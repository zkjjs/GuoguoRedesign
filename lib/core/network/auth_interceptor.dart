// The constructor intentionally exposes stable public argument names while
// storing collaborators in private fields.
// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import 'api_error.dart';

final class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStore tokenStore,
    required SessionRefresher sessionRefresher,
    String? xToken,
  }) : _dio = dio,
       _tokenStore = tokenStore,
       _sessionRefresher = sessionRefresher,
       _xToken = xToken;

  static const _retryKey = 'authRetried';
  static const _generationKey = 'authGeneration';

  /// Refresh transports using this Dio must set this request extra marker.
  /// A 401 for such a request is propagated to the refresher instead of
  /// recursively joining the refresh operation that issued it.
  static const skipAuthRefreshKey = 'skipAuthRefresh';

  final Dio _dio;
  final TokenStore _tokenStore;
  final SessionRefresher _sessionRefresher;
  final String? _xToken;

  Future<_AuthGeneration>? _refreshing;
  _AuthGeneration? _generation;
  int _nextGeneration = 0;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final storedToken = _normalize(await _tokenStore.readUserToken());
      final generation = _synchronize(storedToken);
      final userToken = generation.expired ? null : generation.token;
      _setHeaderIfPresent(options.headers, 'X-Token', _xToken);
      _setHeaderIfPresent(options.headers, 'UserToken', userToken);
      options.extra[_generationKey] = generation.id;
      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.extra[skipAuthRefreshKey] == true) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.extra[_retryKey] == true) {
      final rejected = _generationFor(err.requestOptions);
      _expire(rejected?.id);
      await _clearBestEffort(rejected?.token);
      handler.reject(_authenticationExpired(err));
      return;
    }

    late final _AuthGeneration generation;
    final requestGeneration = _generationIdFor(err.requestOptions);
    try {
      final storedToken = _normalize(await _tokenStore.readUserToken());
      final current = _synchronize(storedToken);
      if (current.expired) {
        await _clearBestEffort(current.token);
        handler.reject(_authenticationExpired(err));
        return;
      }
      if (requestGeneration != null && requestGeneration != current.id) {
        if (current.token == null) {
          handler.reject(_authenticationExpired(err));
          return;
        }
        generation = current;
      } else {
        generation = await (_refreshing ??= _refreshToken());
      }
    } on RefreshAuthenticationRejected {
      final rejected = _generation;
      _expire(rejected?.id);
      await _clearBestEffort(rejected?.token);
      handler.reject(_authenticationExpired(err));
      return;
    } on DioException catch (transientError) {
      handler.reject(transientError);
      return;
    } catch (transientError, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: transientError,
          stackTrace: stackTrace,
        ),
      );
      return;
    }

    try {
      await _replay(err, generation, handler);
    } on DioException catch (replayError) {
      if (replayError.error == ApiError.authenticationExpired ||
          replayError.response?.statusCode == 401) {
        _expire(generation.id);
        await _clearBestEffort(generation.token);
        handler.reject(_authenticationExpired(replayError));
        return;
      }
      handler.reject(replayError);
    } catch (replayError, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: replayError,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> _replay(
    DioException source,
    _AuthGeneration generation,
    ErrorInterceptorHandler handler,
  ) async {
    final replay = source.requestOptions.copyWith(
      headers: Map<String, dynamic>.of(source.requestOptions.headers),
      extra: <String, dynamic>{
        ...source.requestOptions.extra,
        _retryKey: true,
        _generationKey: generation.id,
      },
    );
    _setHeaderIfPresent(replay.headers, 'UserToken', generation.token);
    final response = await _dio.fetch<dynamic>(replay);
    handler.resolve(response);
  }

  Future<_AuthGeneration> _refreshToken() async {
    try {
      final token = await _sessionRefresher.refreshUserToken();
      final normalized = token.trim();
      if (normalized.isEmpty) {
        throw const RefreshAuthenticationRejected();
      }
      await _tokenStore.writeUserToken(normalized);
      return _activate(normalized);
    } finally {
      _refreshing = null;
    }
  }

  DioException _authenticationExpired(DioException source) {
    return source.copyWith(error: ApiError.authenticationExpired);
  }

  Future<void> _clearBestEffort(String? rejectedToken) async {
    if (rejectedToken == null) {
      return;
    }
    try {
      final store = _tokenStore;
      // Generic stores are intentionally left to in-memory invalidation:
      // read-then-clear could delete a concurrent login credential.
      if (store is ConditionalTokenStore) {
        await store.clearIfUserToken(rejectedToken);
      }
    } catch (_) {
      // Authentication rejection remains authoritative even if secure storage
      // is temporarily unavailable. Never log the storage exception or token.
    }
  }

  _AuthGeneration _synchronize(String? storedToken) {
    final current = _generation;
    if (current == null) {
      return _activate(storedToken);
    }
    if (current.expired) {
      if (storedToken != null && storedToken != current.token) {
        return _activate(storedToken);
      }
      return current;
    }
    if (storedToken != current.token) {
      return _activate(storedToken);
    }
    return current;
  }

  _AuthGeneration _activate(String? token) {
    final generation = _AuthGeneration(id: ++_nextGeneration, token: token);
    _generation = generation;
    return generation;
  }

  void _expire(int? generationId) {
    final current = _generation;
    if (current != null && current.id == generationId) {
      current.expired = true;
    }
  }

  int? _generationIdFor(RequestOptions options) {
    final value = options.extra[_generationKey];
    return value is int ? value : null;
  }

  _AuthGeneration? _generationFor(RequestOptions options) {
    final generationId = _generationIdFor(options);
    final current = _generation;
    return current != null && current.id == generationId ? current : null;
  }

  String? _normalize(String? token) {
    final normalized = token?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  void _setHeaderIfPresent(
    Map<String, dynamic> headers,
    String name,
    String? value,
  ) {
    final normalizedName = name.toLowerCase();
    final matchingKeys = headers.keys
        .where((key) => key.toLowerCase() == normalizedName)
        .toList(growable: false);
    for (final key in matchingKeys) {
      headers.remove(key);
    }
    if (value != null && value.isNotEmpty) {
      headers[name] = value;
    }
  }
}

final class _AuthGeneration {
  _AuthGeneration({required this.id, required this.token});

  final int id;
  final String? token;
  bool expired = false;
}
