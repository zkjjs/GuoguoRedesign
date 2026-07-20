import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guoguo/features/player/data/playback_api.dart';
import 'package:guoguo/features/player/data/playback_repository_impl.dart';
import 'package:guoguo/features/player/domain/playback_request.dart';
import 'package:guoguo/features/player/domain/playback_source.dart';

void main() {
  const request = PlaybackRequest(
    mediaId: 'media-1',
    lineId: 'line-2',
    episodeId: 'episode-3',
  );
  final future = DateTime.parse('2099-01-01T00:00:00Z');
  final past = DateTime.parse('2000-01-01T00:00:00Z');

  PlaybackTokenResult token([DateTime? expiresAt]) =>
      PlaybackTokenResult(value: '[REDACTED]', expiresAt: expiresAt ?? future);

  PlaybackAddressResult address({
    String rawPlayUrl = 'https://media.invalid/fixture/master.m3u8',
    Map<String, String> headers = const <String, String>{},
  }) => PlaybackAddressResult(rawPlayUrl: rawPlayUrl, headers: headers);

  group('PlaybackRepositoryImpl', () {
    test(
      'uses typed context, token, address results in strict order',
      () async {
        final api = _FakePlaybackApi(
          tokenResponses: <Object>[token()],
          addressResponses: <Object>[
            address(
              headers: const <String, String>{
                'user-agent': 'fixture-agent',
                'REFERER': 'https://app.invalid/',
                'Cookie': 'must-not-leak',
              },
            ),
          ],
        );

        final source = await PlaybackRepositoryImpl(api: api).resolve(request);

        expect(api.calls, <String>['context', 'token', 'address']);
        expect(api.addressAuthorizationHeaders, <String>['PLAY-TOKEN']);
        expect(
          source.uri,
          Uri.parse('https://media.invalid/fixture/master.m3u8'),
        );
        expect(source.headers, <String, String>{
          'User-Agent': 'fixture-agent',
          'Referer': 'https://app.invalid/',
        });
        expect(source.expiresAt, future);
      },
    );

    test('expired initial token consumes the only refresh', () async {
      final api = _FakePlaybackApi(
        tokenResponses: <Object>[token(past), token()],
        addressResponses: <Object>[address()],
      );

      await PlaybackRepositoryImpl(
        api: api,
        clock: () => _now,
      ).resolve(request);

      expect(api.calls, <String>['context', 'token', 'token', 'address']);
    });

    test('expired refresh is rejected before address request', () async {
      final api = _FakePlaybackApi(
        tokenResponses: <Object>[token(past), token(past)],
      );

      await expectLater(
        PlaybackRepositoryImpl(api: api, clock: () => _now).resolve(request),
        throwsA(_failure(PlaybackFailureKind.tokenExpiredAfterRefresh)),
      );
      expect(api.calls, <String>['context', 'token', 'token']);
    });

    test('expiry then 401 never performs a third token request', () async {
      final api = _FakePlaybackApi(
        tokenResponses: <Object>[token(past), token()],
        addressResponses: <Object>[const PlaybackApiFailure.unauthorized()],
      );

      await expectLater(
        PlaybackRepositoryImpl(api: api, clock: () => _now).resolve(request),
        throwsA(_failure(PlaybackFailureKind.unauthorizedAfterRefresh)),
      );
      expect(api.calls, <String>['context', 'token', 'token', 'address']);
    });

    test('token refreshed after 401 is expiry-checked before retry', () async {
      final api = _FakePlaybackApi(
        tokenResponses: <Object>[token(), token(past)],
        addressResponses: <Object>[const PlaybackApiFailure.unauthorized()],
      );

      await expectLater(
        PlaybackRepositoryImpl(api: api, clock: () => _now).resolve(request),
        throwsA(_failure(PlaybackFailureKind.tokenExpiredAfterRefresh)),
      );
      expect(api.calls, <String>['context', 'token', 'address', 'token']);
    });

    test('a second 401 is returned without a third token call', () async {
      final api = _FakePlaybackApi(
        tokenResponses: <Object>[token(), token()],
        addressResponses: <Object>[
          const PlaybackApiFailure.unauthorized(),
          const PlaybackApiFailure.unauthorized(),
        ],
      );

      await expectLater(
        PlaybackRepositoryImpl(api: api).resolve(request),
        throwsA(_failure(PlaybackFailureKind.unauthorizedAfterRefresh)),
      );
      expect(api.calls, <String>[
        'context',
        'token',
        'address',
        'token',
        'address',
      ]);
    });

    for (final testCase
        in <({String name, String url, PlaybackFailureKind kind})>[
          (name: 'empty URL', url: '', kind: PlaybackFailureKind.emptyUrl),
          (
            name: 'non-http URL',
            url: 'file:///private/media.mov',
            kind: PlaybackFailureKind.unsupportedScheme,
          ),
          (
            name: 'authority-less URL',
            url: 'https:relative',
            kind: PlaybackFailureKind.invalidAddress,
          ),
        ]) {
      test('${testCase.name} has a distinct failure kind', () async {
        final api = _FakePlaybackApi(
          tokenResponses: <Object>[token()],
          addressResponses: <Object>[address(rawPlayUrl: testCase.url)],
        );
        await expectLater(
          PlaybackRepositoryImpl(api: api).resolve(request),
          throwsA(_failure(testCase.kind)),
        );
      });
    }

    test('adapter malformed-token failure remains distinct', () async {
      final api = _FakePlaybackApi(
        tokenResponses: const <Object>[PlaybackApiFailure.malformedToken()],
      );
      await expectLater(
        PlaybackRepositoryImpl(api: api).resolve(request),
        throwsA(_failure(PlaybackFailureKind.malformedToken)),
      );
    });

    for (final failureCase
        in <({String name, Object failure, PlaybackFailureKind kind})>[
          (
            name: 'timeout',
            failure: TimeoutException('fixture'),
            kind: PlaybackFailureKind.timeout,
          ),
          (
            name: 'cancellation',
            failure: const PlaybackApiFailure.cancelled(),
            kind: PlaybackFailureKind.cancelled,
          ),
        ]) {
      for (final phase in _FailurePhase.values) {
        test(
          '${failureCase.name} maps consistently during ${phase.name}',
          () async {
            final api = _apiFailingAt(phase, failureCase.failure);
            await expectLater(
              PlaybackRepositoryImpl(api: api).resolve(request),
              throwsA(_failure(failureCase.kind)),
            );
          },
        );
      }
    }

    test('headers are canonical, first-wins, and injection-safe', () async {
      final api = _FakePlaybackApi(
        tokenResponses: <Object>[token()],
        addressResponses: <Object>[
          address(
            headers: const <String, String>{
              'referer': 'https://first.invalid/',
              'Referer': 'https://duplicate.invalid/',
              'Origin': 'safe\r\nX-Evil: injected-value',
              'ORIGIN': 'https://origin.invalid/',
              'user-agent': 'safe-agent',
              'User-Agent\r\nX-Evil': 'injected-name',
              'Cookie': 'blocked',
            },
          ),
        ],
      );

      final source = await PlaybackRepositoryImpl(api: api).resolve(request);

      expect(source.headers, <String, String>{
        'Referer': 'https://first.invalid/',
        'Origin': 'https://origin.invalid/',
        'User-Agent': 'safe-agent',
      });
    });

    test('source copies headers and redacts diagnostics', () {
      final mutable = <String, String>{'Referer': 'https://safe.invalid/'};
      final source = PlaybackSource(
        uri: Uri.parse('https://secret.invalid/watch?token=secret'),
        headers: mutable,
        expiresAt: null,
      );
      mutable['Authorization'] = 'secret';

      expect(source.headers, <String, String>{
        'Referer': 'https://safe.invalid/',
      });
      expect(() => source.headers['Other'] = 'value', throwsUnsupportedError);
      expect(source.toString(), contains('uri: [REDACTED]'));
      expect(source.toString(), contains('headers: [REDACTED]'));
      expect(source.toString(), isNot(contains('secret')));
    });

    test('capture is disabled by default', () {
      final recorder = ContractCaptureRecorder();
      recorder.record(
        fields: const <String, Object?>{'field': 'sentinel-secret'},
        statusCode: 200,
        elapsed: const Duration(milliseconds: 12),
      );
      expect(recorder.enabled, isFalse);
      expect(recorder.observations, isEmpty);
    });

    test('capture sink receives nested shapes and never values', () {
      final emitted = <ContractObservation>[];
      final recorder = ContractCaptureRecorder(
        enabled: true,
        sink: emitted.add,
      );
      recorder.record(
        fields: const <String, Object?>{
          'items': <Object?>[
            <String, Object?>{'token': 'sentinel-secret'},
          ],
        },
        statusCode: 201,
        elapsed: const Duration(milliseconds: 12),
      );

      final observation = emitted.single;
      expect(recorder.observations.single, same(observation));
      expect(
        observation.fields.map((field) => (field.name, field.type)),
        <(String, String)>[
          ('items', 'list'),
          ('items[]', 'object'),
          ('items[].token', 'string'),
        ],
      );
      expect(observation.toString(), isNot(contains('sentinel-secret')));
      for (final shape in observation.fields) {
        expect(shape.name, isNot(contains('sentinel-secret')));
        expect(shape.type, isNot(contains('sentinel-secret')));
      }
    });
  });
}

final _now = DateTime.parse('2026-07-20T00:00:00Z');

enum _FailurePhase {
  context,
  initialToken,
  firstAddress,
  refreshedToken,
  retriedAddress,
}

_FakePlaybackApi _apiFailingAt(_FailurePhase phase, Object failure) {
  PlaybackTokenResult token() => PlaybackTokenResult(
    value: '[REDACTED]',
    expiresAt: DateTime.parse('2099-01-01T00:00:00Z'),
  );
  const address = PlaybackAddressResult(
    rawPlayUrl: 'https://media.invalid/fixture/master.m3u8',
    headers: <String, String>{},
  );
  return _FakePlaybackApi(
    contextFailure: phase == _FailurePhase.context ? failure : null,
    tokenResponses: <Object>[
      if (phase == _FailurePhase.initialToken) failure else token(),
      if (phase == _FailurePhase.refreshedToken) failure else token(),
    ],
    addressResponses: <Object>[
      if (phase == _FailurePhase.firstAddress)
        failure
      else if (phase == _FailurePhase.refreshedToken ||
          phase == _FailurePhase.retriedAddress)
        const PlaybackApiFailure.unauthorized()
      else
        address,
      if (phase == _FailurePhase.retriedAddress) failure else address,
    ],
  );
}

Matcher _failure(PlaybackFailureKind kind) =>
    isA<PlaybackFailure>().having((failure) => failure.kind, 'kind', kind);

final class _FakePlaybackApi implements PlaybackApi {
  _FakePlaybackApi({
    this.contextFailure,
    List<Object> tokenResponses = const <Object>[],
    List<Object> addressResponses = const <Object>[],
  }) : _tokenResponses = List<Object>.of(tokenResponses),
       _addressResponses = List<Object>.of(addressResponses);

  final Object? contextFailure;
  final List<Object> _tokenResponses;
  final List<Object> _addressResponses;
  final List<String> calls = <String>[];
  final List<String> addressAuthorizationHeaders = <String>[];

  @override
  Future<PlaybackContext> resolveContext(PlaybackRequest request) async {
    calls.add('context');
    if (contextFailure case final failure?) throw failure;
    return PlaybackContext.fromRequest(request);
  }

  @override
  Future<PlaybackTokenResult> requestToken(PlaybackContext context) async {
    calls.add('token');
    return _next<PlaybackTokenResult>(_tokenResponses);
  }

  @override
  Future<PlaybackAddressResult> requestAddress(
    PlaybackContext context, {
    required String authorizationHeader,
    required String token,
  }) async {
    calls.add('address');
    addressAuthorizationHeaders.add(authorizationHeader);
    return _next<PlaybackAddressResult>(_addressResponses);
  }

  T _next<T>(List<Object> values) {
    if (values.isEmpty) throw StateError('Missing fake response');
    final response = values.removeAt(0);
    if (response is Exception) throw response;
    return response as T;
  }
}
