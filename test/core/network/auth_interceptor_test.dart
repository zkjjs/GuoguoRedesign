import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoguo/core/auth/auth_session.dart';
import 'package:guoguo/core/network/api_error.dart';
import 'package:guoguo/core/network/auth_interceptor.dart';

void main() {
  test('authenticated requests receive both available token headers', () async {
    final adapter = _ScriptedAdapter((_) => const _Reply(200));
    final dio = _dio(adapter);
    final store = _MemoryTokenStore('user-token');
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStore: store,
        sessionRefresher: _SessionRefresher(() async => 'unused'),
        xToken: 'app-token',
      ),
    );

    await dio.get<void>('/detail');

    expect(adapter.requests.single.headers['X-Token'], 'app-token');
    expect(adapter.requests.single.headers['UserToken'], 'user-token');
    expect(
      adapter.requests.single.extra.toString(),
      isNot(contains('user-token')),
    );
    expect(
      adapter.requests.single.extra.toString(),
      isNot(contains('app-token')),
    );
  });

  test('unavailable token headers are omitted', () async {
    final adapter = _ScriptedAdapter((_) => const _Reply(200));
    final dio = _dio(adapter);
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStore: _MemoryTokenStore(null),
        sessionRefresher: _SessionRefresher(() async => 'unused'),
      ),
    );

    await dio.get<void>('/detail');

    expect(adapter.requests.single.headers, isNot(contains('X-Token')));
    expect(adapter.requests.single.headers, isNot(contains('UserToken')));
  });

  test('concurrent 401 responses share refresh and replay once', () async {
    final releaseRefresh = Completer<String>();
    var refreshCount = 0;
    final attempts = <String, int>{};
    final adapter = _ScriptedAdapter((request) {
      final path = request.path;
      final attempt = attempts.update(
        path,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      return _Reply(attempt == 1 ? 401 : 200);
    });
    final dio = _dio(adapter);
    final store = _MemoryTokenStore('expired');
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStore: store,
        sessionRefresher: _SessionRefresher(() {
          refreshCount += 1;
          return releaseRefresh.future;
        }),
      ),
    );

    final first = dio.get<void>('/first');
    final second = dio.get<void>('/second');
    await Future<void>.delayed(Duration.zero);
    releaseRefresh.complete('fresh');
    await Future.wait([first, second]);

    expect(refreshCount, 1);
    expect(attempts, {'/first': 2, '/second': 2});
    final replays = adapter.requests.where(
      (request) => request.extra['authRetried'] == true,
    );
    expect(replays, hasLength(2));
    expect(
      replays.every((request) => request.headers['UserToken'] == 'fresh'),
      isTrue,
    );
  });

  test('late 401 sent with old token reuses refreshed generation', () async {
    final releaseLate401 = Completer<void>();
    var refreshCount = 0;
    final attempts = <String, int>{};
    final adapter = _ScriptedAdapter((request) async {
      final attempt = attempts.update(
        request.path,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if (request.path == '/late' && attempt == 1) {
        await releaseLate401.future;
      }
      return _Reply(attempt == 1 ? 401 : 200);
    });
    final dio = _dio(adapter);
    final store = _MemoryTokenStore('expired');
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStore: store,
        sessionRefresher: _SessionRefresher(() async {
          refreshCount += 1;
          return 'fresh';
        }),
      ),
    );

    final late = dio.get<void>('/late');
    await dio.get<void>('/first');
    releaseLate401.complete();
    await late;

    expect(refreshCount, 1);
    expect(attempts, {'/late': 2, '/first': 2});
  });

  test(
    'rejected fresh generation expires a later old-generation 401',
    () async {
      final releaseLate401 = Completer<void>();
      var refreshCount = 0;
      final attempts = <String, int>{};
      final adapter = _ScriptedAdapter((request) async {
        final attempt = attempts.update(
          request.path,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        if (request.path == '/late' && attempt == 1) {
          await releaseLate401.future;
        }
        return const _Reply(401);
      });
      final dio = _dio(adapter);
      final store = _MemoryTokenStore('expired');
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          tokenStore: store,
          sessionRefresher: _SessionRefresher(() async {
            refreshCount += 1;
            return 'fresh';
          }),
        ),
      );

      final late = dio.get<void>('/late');
      await expectLater(
        dio.get<void>('/first'),
        throwsA(_authenticationExpiredMatcher),
      );
      releaseLate401.complete();
      await expectLater(late, throwsA(_authenticationExpiredMatcher));

      expect(refreshCount, 1);
      expect(attempts, {'/late': 1, '/first': 2});
      expect(
        adapter.requests.every(
          (request) =>
              !request.extra.toString().contains('expired') &&
              !request.extra.toString().contains('fresh'),
        ),
        isTrue,
      );
    },
  );

  test(
    'failed durable clear still suppresses rejected token and refresh',
    () async {
      var refreshCount = 0;
      final attempts = <String, int>{};
      final adapter = _ScriptedAdapter((request) {
        attempts.update(request.path, (value) => value + 1, ifAbsent: () => 1);
        if (request.path == '/after-sign-in') {
          return const _Reply(200);
        }
        return const _Reply(401);
      });
      final store = _MemoryTokenStore('expired')
        ..clearFailure = StateError('keychain unavailable');
      final dio = _dio(adapter);
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          tokenStore: store,
          sessionRefresher: _SessionRefresher(() async {
            refreshCount += 1;
            return 'fresh';
          }),
        ),
      );

      await expectLater(
        dio.get<void>('/reject'),
        throwsA(_authenticationExpiredMatcher),
      );
      expect(store.value, 'fresh');
      await expectLater(
        dio.get<void>('/after-reject'),
        throwsA(_authenticationExpiredMatcher),
      );

      final afterReject = adapter.requests.last;
      expect(afterReject.headers, isNot(contains('UserToken')));
      expect(refreshCount, 1);
      expect(attempts['/after-reject'], 1);

      store.value = 'signed-in-new';
      await dio.get<void>('/after-sign-in');
      expect(adapter.requests.last.headers['UserToken'], 'signed-in-new');
      expect(refreshCount, 1);
    },
  );

  test('generic token store is never cleared with a racy fallback', () async {
    final store = _NonConditionalTokenStore('expired');
    final dio = _dio(_ScriptedAdapter((_) => const _Reply(401)));
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStore: store,
        sessionRefresher: _SessionRefresher(() async => 'fresh'),
      ),
    );

    await expectLater(
      dio.get<void>('/reject'),
      throwsA(_authenticationExpiredMatcher),
    );

    expect(store.clearCount, 0);
    expect(store.value, 'fresh');
  });

  test('refresh request marked to skip auth refresh cannot deadlock', () async {
    late Dio dio;
    var refreshRequests = 0;
    final adapter = _ScriptedAdapter((request) {
      if (request.path == '/refresh') {
        refreshRequests += 1;
      }
      return const _Reply(401);
    });
    dio = _dio(adapter);
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStore: _MemoryTokenStore('expired'),
        sessionRefresher: _SessionRefresher(() async {
          await dio.get<void>(
            '/refresh',
            options: Options(extra: {AuthInterceptor.skipAuthRefreshKey: true}),
          );
          return 'unreachable';
        }),
      ),
    );

    await expectLater(
      dio.get<void>('/detail').timeout(const Duration(seconds: 1)),
      throwsA(isA<DioException>()),
    );
    expect(refreshRequests, 1);
  });

  test(
    'confirmed refresh rejection clears token and expires authentication',
    () async {
      final store = _MemoryTokenStore('expired');
      final dio = _dio(_ScriptedAdapter((_) => const _Reply(401)));
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          tokenStore: store,
          sessionRefresher: _SessionRefresher(
            () async => throw const RefreshAuthenticationRejected(),
          ),
        ),
      );

      await expectLater(
        dio.get<void>('/detail'),
        throwsA(
          isA<DioException>().having(
            (error) => error.error,
            'error',
            ApiError.authenticationExpired,
          ),
        ),
      );
      expect(store.value, isNull);
    },
  );

  test(
    'transient refresh failure preserves original error and token',
    () async {
      final transient = DioException.connectionTimeout(
        requestOptions: RequestOptions(path: '/refresh'),
        timeout: const Duration(seconds: 5),
      );
      final store = _MemoryTokenStore('expired');
      final dio = _dio(_ScriptedAdapter((_) => const _Reply(401)));
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          tokenStore: store,
          sessionRefresher: _SessionRefresher(() async => throw transient),
        ),
      );

      await expectLater(dio.get<void>('/detail'), throwsA(same(transient)));
      expect(store.value, 'expired');
    },
  );

  test('storage failure preserves original error and existing token', () async {
    final failure = StateError('keychain unavailable');
    final store = _MemoryTokenStore('expired')..writeFailure = failure;
    final dio = _dio(_ScriptedAdapter((_) => const _Reply(401)));
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStore: store,
        sessionRefresher: _SessionRefresher(() async => 'fresh'),
      ),
    );

    await expectLater(
      dio.get<void>('/detail'),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          same(failure),
        ),
      ),
    );
    expect(store.value, 'expired');
  });

  test('blank refreshed token is never persisted', () async {
    final store = _MemoryTokenStore('expired');
    final dio = _dio(_ScriptedAdapter((_) => const _Reply(401)));
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStore: store,
        sessionRefresher: _SessionRefresher(() async => '  '),
      ),
    );

    await expectLater(
      dio.get<void>('/detail'),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          ApiError.authenticationExpired,
        ),
      ),
    );
    expect(store.writtenValues, isEmpty);
  });

  test(
    'all mixed-case token header variants are replaced or removed',
    () async {
      final adapter = _ScriptedAdapter((_) => const _Reply(200));
      final dio = _dio(adapter);
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          tokenStore: _MemoryTokenStore('fresh'),
          sessionRefresher: _SessionRefresher(() async => 'unused'),
        ),
      );
      await dio.get<void>(
        '/with-token',
        options: Options(headers: {'usertoken': 'a', 'USERTOKEN': 'b'}),
      );

      final injected = adapter.requests.single.headers;
      expect(injected.keys.where((key) => key.toLowerCase() == 'usertoken'), [
        'UserToken',
      ]);
      expect(injected['UserToken'], 'fresh');

      final omittedAdapter = _ScriptedAdapter((_) => const _Reply(200));
      final omittedDio = _dio(omittedAdapter);
      omittedDio.interceptors.add(
        AuthInterceptor(
          dio: omittedDio,
          tokenStore: _MemoryTokenStore(null),
          sessionRefresher: _SessionRefresher(() async => 'unused'),
        ),
      );
      await omittedDio.get<void>(
        '/without-token',
        options: Options(headers: {'usertoken': 'a', 'USERTOKEN': 'b'}),
      );
      expect(
        omittedAdapter.requests.single.headers.keys.where(
          (key) => key.toLowerCase() == 'usertoken',
        ),
        isEmpty,
      );
    },
  );

  test('a replayed 401 expires authentication without recursion', () async {
    var refreshCount = 0;
    final adapter = _ScriptedAdapter((_) => const _Reply(401));
    final dio = _dio(adapter);
    final store = _MemoryTokenStore('expired');
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStore: store,
        sessionRefresher: _SessionRefresher(() async {
          refreshCount += 1;
          return 'still-invalid';
        }),
      ),
    );

    await expectLater(
      dio.get<void>('/detail'),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          ApiError.authenticationExpired,
        ),
      ),
    );
    expect(refreshCount, 1);
    expect(adapter.requests, hasLength(2));
    expect(store.value, isNull);
  });
}

Dio _dio(HttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter;
}

final class _MemoryTokenStore implements TokenStore, ConditionalTokenStore {
  _MemoryTokenStore(this.value);

  String? value;
  Object? writeFailure;
  Object? clearFailure;
  final List<String> writtenValues = [];

  @override
  Future<void> clear() async {
    if (clearFailure case final failure?) {
      throw failure;
    }
    value = null;
  }

  @override
  Future<String?> readUserToken() async => value;

  @override
  Future<void> writeUserToken(String value) async {
    if (writeFailure case final failure?) {
      throw failure;
    }
    writtenValues.add(value);
    this.value = value;
  }

  @override
  Future<bool> clearIfUserToken(String expected) async {
    if (clearFailure case final failure?) {
      throw failure;
    }
    if (value != expected) {
      return false;
    }
    value = null;
    return true;
  }
}

final class _NonConditionalTokenStore implements TokenStore {
  _NonConditionalTokenStore(this.value);

  String? value;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount += 1;
    value = null;
  }

  @override
  Future<String?> readUserToken() async => value;

  @override
  Future<void> writeUserToken(String value) async => this.value = value;
}

final _authenticationExpiredMatcher = isA<DioException>().having(
  (error) => error.error,
  'error',
  ApiError.authenticationExpired,
);

final class _SessionRefresher implements SessionRefresher {
  const _SessionRefresher(this.callback);

  final Future<String> Function() callback;

  @override
  Future<String> refreshUserToken() => callback();
}

final class _Reply {
  const _Reply(this.statusCode);

  final int statusCode;
}

final class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.callback);

  final FutureOr<_Reply> Function(RequestOptions request) callback;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      options.copyWith(
        headers: Map<String, dynamic>.of(options.headers),
        extra: Map<String, dynamic>.of(options.extra),
      ),
    );
    final reply = await callback(options);
    return ResponseBody.fromString(
      '{}',
      reply.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
