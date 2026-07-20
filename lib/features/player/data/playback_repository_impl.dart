// The repository keeps a stable public `api` argument while storing the
// adapter privately.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import '../domain/playback_repository.dart';
import '../domain/playback_request.dart';
import '../domain/playback_source.dart';
import 'playback_api.dart';

typedef PlaybackClock = DateTime Function();

final class PlaybackRepositoryImpl implements PlaybackRepository {
  PlaybackRepositoryImpl({required PlaybackApi api, PlaybackClock? clock})
    : _api = api,
      _clock = clock ?? DateTime.now;

  static const _canonicalAddressHeaders = <String, String>{
    'origin': 'Origin',
    'referer': 'Referer',
    'user-agent': 'User-Agent',
  };

  final PlaybackApi _api;
  final PlaybackClock _clock;

  @override
  Future<PlaybackSource> resolve(PlaybackRequest request) async {
    try {
      final context = await _api.resolveContext(request);
      var refreshes = 0;
      var token = await _api.requestToken(context);

      if (_isExpired(token)) {
        refreshes += 1;
        token = await _api.requestToken(context);
        _requireUsableRefresh(token);
      }

      PlaybackAddressResult address;
      try {
        address = await _requestAddress(context, token.value);
      } on PlaybackApiFailure catch (error) {
        if (error.kind != PlaybackApiFailureKind.unauthorized) rethrow;
        if (refreshes >= 1) {
          throw const PlaybackFailure(
            PlaybackFailureKind.unauthorizedAfterRefresh,
          );
        }

        refreshes += 1;
        token = await _api.requestToken(context);
        _requireUsableRefresh(token);
        try {
          address = await _requestAddress(context, token.value);
        } on PlaybackApiFailure catch (secondError) {
          if (secondError.kind == PlaybackApiFailureKind.unauthorized) {
            throw const PlaybackFailure(
              PlaybackFailureKind.unauthorizedAfterRefresh,
            );
          }
          rethrow;
        }
      }

      return _toSource(address, expiresAt: token.expiresAt);
    } on PlaybackFailure {
      rethrow;
    } on TimeoutException {
      throw const PlaybackFailure(PlaybackFailureKind.timeout);
    } on PlaybackApiFailure catch (error) {
      throw switch (error.kind) {
        PlaybackApiFailureKind.cancelled => const PlaybackFailure(
          PlaybackFailureKind.cancelled,
        ),
        PlaybackApiFailureKind.malformedToken => const PlaybackFailure(
          PlaybackFailureKind.malformedToken,
        ),
        PlaybackApiFailureKind.unauthorized => const PlaybackFailure(
          PlaybackFailureKind.unauthorizedAfterRefresh,
        ),
      };
    }
  }

  Future<PlaybackAddressResult> _requestAddress(
    PlaybackContext context,
    String token,
  ) {
    return _api.requestAddress(
      context,
      authorizationHeader: PlaybackStaticContract.authorizationHeader,
      token: token,
    );
  }

  bool _isExpired(PlaybackTokenResult token) {
    final expiresAt = token.expiresAt;
    return expiresAt != null && !expiresAt.isAfter(_clock().toUtc());
  }

  void _requireUsableRefresh(PlaybackTokenResult token) {
    if (_isExpired(token)) {
      throw const PlaybackFailure(PlaybackFailureKind.tokenExpiredAfterRefresh);
    }
  }

  PlaybackSource _toSource(
    PlaybackAddressResult address, {
    DateTime? expiresAt,
  }) {
    final rawUrl = address.rawPlayUrl.trim();
    if (rawUrl.isEmpty) {
      throw const PlaybackFailure(PlaybackFailureKind.emptyUrl);
    }

    final Uri uri;
    try {
      uri = Uri.parse(rawUrl);
    } on FormatException {
      throw const PlaybackFailure(PlaybackFailureKind.invalidAddress);
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const PlaybackFailure(PlaybackFailureKind.unsupportedScheme);
    }
    if (!uri.hasAuthority || uri.host.isEmpty) {
      throw const PlaybackFailure(PlaybackFailureKind.invalidAddress);
    }

    final headers = <String, String>{};
    for (final entry in address.headers.entries) {
      if (_containsNewline(entry.key) || _containsNewline(entry.value)) {
        continue;
      }
      final canonical = _canonicalAddressHeaders[entry.key.toLowerCase()];
      if (canonical == null || headers.containsKey(canonical)) continue;
      headers[canonical] = entry.value;
    }

    return PlaybackSource(uri: uri, headers: headers, expiresAt: expiresAt);
  }

  bool _containsNewline(String value) {
    return value.contains('\r') || value.contains('\n');
  }
}
