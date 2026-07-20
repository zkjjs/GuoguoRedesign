import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoguo/core/network/redacting_log_interceptor.dart';

void main() {
  test(
    'redacts sensitive headers and nested request values case-insensitively',
    () {
      final events = <Map<String, Object?>>[];
      final interceptor = RedactingLogInterceptor(events.add);
      final options = RequestOptions(
        path: '/play',
        headers: {
          'Authorization': 'secret',
          'X-Token': 'app',
          'Accept': 'json',
        },
        queryParameters: {'SIGN': 'signature', 'page': 2},
        data: {
          'mobile': '13000000000',
          'profile': {
            'USER_ID': 7,
            'items': [
              {'raw_play_url': 'https://secret.test/video', 'title': 'safe'},
            ],
          },
        },
      );

      interceptor.onRequest(options, _NoopRequestHandler());

      final rendered = events.single.toString();
      expect(rendered, contains('[REDACTED]'));
      expect(rendered, isNot(contains('secret')));
      expect(rendered, isNot(contains('signature')));
      expect(rendered, isNot(contains('13000000000')));
      expect(rendered, isNot(contains('https://secret.test/video')));
      expect(rendered, contains('page: 2'));
      expect(rendered, contains('title: safe'));
      expect(rendered, contains('Accept: json'));
    },
  );

  test('logging never mutates the outgoing request', () {
    final interceptor = RedactingLogInterceptor((_) {});
    final body = {
      'token': 'body-token',
      'nested': {'mobile': '13000000000'},
    };
    final options = RequestOptions(
      path: '/play',
      headers: {'UserToken': 'header-token'},
      queryParameters: {'sign': 'query-sign'},
      data: body,
    );

    interceptor.onRequest(options, _NoopRequestHandler());

    expect(options.headers['UserToken'], 'header-token');
    expect(options.queryParameters['sign'], 'query-sign');
    expect((options.data as Map)['token'], 'body-token');
    expect(((options.data as Map)['nested'] as Map)['mobile'], '13000000000');
  });

  test('detaches and redacts form data while keeping safe file metadata', () {
    late Map<String, Object?> event;
    final interceptor = RedactingLogInterceptor((value) => event = value);
    final form = FormData.fromMap({
      'token': 'body-token',
      'title': 'safe',
      'upload': MultipartFile.fromBytes([1, 2, 3], filename: 'poster.jpg'),
    });
    final options = RequestOptions(path: '/upload', data: form);

    interceptor.onRequest(options, _NoopRequestHandler());
    final titleIndex = form.fields.indexWhere((entry) => entry.key == 'title');
    form.fields[titleIndex] = const MapEntry('title', 'changed');

    final rendered = event.toString();
    expect(rendered, isNot(contains('body-token')));
    expect(rendered, contains('[REDACTED]'));
    expect(rendered, contains('safe'));
    expect(rendered, isNot(contains('changed')));
    expect(rendered, contains('poster.jpg'));
    expect(rendered, contains('length: 3'));
    expect(rendered, isNot(contains('Instance of')));
  });

  test('unsupported bodies become detached type markers', () {
    final body = _OpaqueBody();
    late Map<String, Object?> event;
    final interceptor = RedactingLogInterceptor((value) => event = value);

    interceptor.onRequest(
      RequestOptions(path: '/opaque', data: body),
      _NoopRequestHandler(),
    );

    expect(event['body'], {'type': '_OpaqueBody'});
    expect(event['body'], isNot(same(body)));
  });

  test('redacts embedded path query without hiding safe values', () {
    late Map<String, Object?> event;
    final interceptor = RedactingLogInterceptor((value) => event = value);

    interceptor.onRequest(
      RequestOptions(path: '/play?TOKEN=secret&episode=12'),
      _NoopRequestHandler(),
    );

    final rendered = event.toString();
    expect(rendered, isNot(contains('secret')));
    expect(rendered, contains('[REDACTED]'));
    expect(rendered, contains('episode'));
    expect(rendered, contains('12'));
  });
}

final class _OpaqueBody {}

final class _NoopRequestHandler extends RequestInterceptorHandler {
  @override
  void next(RequestOptions requestOptions) {}
}
