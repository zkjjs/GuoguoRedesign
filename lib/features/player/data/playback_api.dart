import '../domain/playback_request.dart';

abstract interface class PlaybackApi {
  Future<PlaybackContext> resolveContext(PlaybackRequest request);

  Future<PlaybackTokenResult> requestToken(PlaybackContext context);

  Future<PlaybackAddressResult> requestAddress(
    PlaybackContext context, {
    required String authorizationHeader,
    required String token,
  });
}

/// A typed, wire-format-independent result produced by an authorized adapter.
final class PlaybackTokenResult {
  const PlaybackTokenResult({required this.value, required this.expiresAt});

  final String value;
  final DateTime? expiresAt;
}

/// A typed, wire-format-independent result produced by an authorized adapter.
final class PlaybackAddressResult {
  const PlaybackAddressResult({
    required this.rawPlayUrl,
    required this.headers,
  });

  final String rawPlayUrl;
  final Map<String, String> headers;
}

abstract final class PlaybackStaticContract {
  static const baseHost = 'https://vod.api.zshtys888.com';
  static const tokenEndpoint = '/app/playaddr/get/token';
  static const addressEndpoint = '/app/playaddr/v3/get';
  static const authorizationHeader = 'PLAY-TOKEN';
  static const rawPlayUrlField = 'raw_play_url';
}

enum PlaybackApiFailureKind { unauthorized, cancelled, malformedToken }

final class PlaybackApiFailure implements Exception {
  const PlaybackApiFailure.unauthorized()
    : kind = PlaybackApiFailureKind.unauthorized;

  const PlaybackApiFailure.cancelled()
    : kind = PlaybackApiFailureKind.cancelled;

  const PlaybackApiFailure.malformedToken()
    : kind = PlaybackApiFailureKind.malformedToken;

  final PlaybackApiFailureKind kind;
}

typedef ContractCaptureSink = void Function(ContractObservation observation);

final class ContractObservation {
  ContractObservation({
    required Iterable<ContractFieldShape> fields,
    required this.statusCode,
    required this.elapsed,
  }) : fields = List<ContractFieldShape>.unmodifiable(fields);

  final List<ContractFieldShape> fields;
  final int statusCode;
  final Duration elapsed;
}

final class ContractFieldShape {
  const ContractFieldShape({required this.name, required this.type});

  final String name;
  final String type;
}

final class ContractCaptureRecorder {
  ContractCaptureRecorder({
    this.enabled = const bool.fromEnvironment(
      'GUOGUO_CONTRACT_CAPTURE',
      defaultValue: false,
    ),
    ContractCaptureSink? sink,
  }) : _sink = sink;

  final bool enabled;
  final ContractCaptureSink? _sink;
  final List<ContractObservation> _observations = <ContractObservation>[];

  List<ContractObservation> get observations =>
      List<ContractObservation>.unmodifiable(_observations);

  void record({
    required Map<String, Object?> fields,
    required int statusCode,
    required Duration elapsed,
  }) {
    if (!enabled) return;

    final observation = ContractObservation(
      fields: _fieldShapes(fields),
      statusCode: statusCode,
      elapsed: elapsed,
    );
    _observations.add(observation);
    _sink?.call(observation);
  }

  Iterable<ContractFieldShape> _fieldShapes(
    Map<String, Object?> fields, [
    String prefix = '',
  ]) sync* {
    for (final entry in fields.entries) {
      final name = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      final value = entry.value;
      yield ContractFieldShape(name: name, type: _typeName(value));
      yield* _childShapes(value, name);
    }
  }

  Iterable<ContractFieldShape> _childShapes(Object? value, String path) sync* {
    if (value is Map<String, Object?>) {
      yield* _fieldShapes(value, path);
      return;
    }
    if (value is List<Object?>) {
      for (final element in value) {
        final elementPath = '$path[]';
        yield ContractFieldShape(name: elementPath, type: _typeName(element));
        yield* _childShapes(element, elementPath);
      }
    }
  }

  String _typeName(Object? value) {
    return switch (value) {
      null => 'null',
      bool() => 'bool',
      int() => 'int',
      double() => 'double',
      String() => 'string',
      List<Object?>() => 'list',
      Map<String, Object?>() => 'object',
      _ => 'other',
    };
  }
}
