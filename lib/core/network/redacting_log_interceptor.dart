import 'package:dio/dio.dart';

typedef RedactedLogSink = void Function(Map<String, Object?> event);

final class RedactingLogInterceptor extends Interceptor {
  RedactingLogInterceptor(this._sink);

  static const redacted = '[REDACTED]';
  static const _sensitiveKeys = {
    'authorization',
    'cookie',
    'set-cookie',
    'token',
    'x-token',
    'usertoken',
    'play-token',
    'sign',
    'mobile',
    'user_id',
    'raw_play_url',
  };

  final RedactedLogSink _sink;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = _redactPath(options.path);
    _sink({
      'method': options.method,
      ...path,
      'headers': _redactMap(options.headers),
      'query': _redactMap(options.queryParameters),
      'body': _redactBody(options.data),
    });
    handler.next(options);
  }

  Map<String, Object?> _redactMap(Map<Object?, Object?> source) {
    return <String, Object?>{
      for (final entry in source.entries)
        entry.key.toString(): _isSensitive(entry.key)
            ? redacted
            : _redactValue(entry.value),
    };
  }

  Object? _redactValue(Object? value) {
    if (value is Map) {
      return _redactMap(value.cast<Object?, Object?>());
    }
    if (value is Iterable) {
      return value.map(_redactValue).toList(growable: false);
    }
    return value;
  }

  Object? _redactBody(Object? value) {
    if (value == null || value is Map || value is Iterable) {
      return _redactValue(value);
    }
    if (value is FormData) {
      return {
        'fields': [
          for (final field in value.fields)
            {
              'name': field.key,
              'value': _isSensitive(field.key) ? redacted : field.value,
            },
        ],
        'files': [
          for (final entry in value.files)
            _isSensitive(entry.key)
                ? {'name': entry.key, 'value': redacted}
                : {
                    'name': entry.key,
                    'filename': entry.value.filename,
                    'contentType': entry.value.contentType?.toString(),
                    'length': entry.value.length,
                  },
        ],
      };
    }
    return {'type': value.runtimeType.toString()};
  }

  Map<String, Object?> _redactPath(String rawPath) {
    final queryStart = rawPath.indexOf('?');
    if (queryStart < 0) {
      return {'path': rawPath};
    }
    final path = rawPath.substring(0, queryStart);
    final queryWithFragment = rawPath.substring(queryStart + 1);
    final fragmentStart = queryWithFragment.indexOf('#');
    final query = fragmentStart < 0
        ? queryWithFragment
        : queryWithFragment.substring(0, fragmentStart);
    try {
      return {
        'path': path,
        'embeddedQuery': _redactMap(Uri.splitQueryString(query)),
      };
    } on FormatException {
      return {
        'path': path,
        'embeddedQuery': {'type': 'malformed'},
      };
    }
  }

  bool _isSensitive(Object? key) {
    return _sensitiveKeys.contains(key.toString().toLowerCase());
  }
}
