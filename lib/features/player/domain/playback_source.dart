final class PlaybackSource {
  PlaybackSource({
    required this.uri,
    required Map<String, String> headers,
    required this.expiresAt,
  }) : headers = Map<String, String>.unmodifiable(headers);

  final Uri uri;
  final Map<String, String> headers;
  final DateTime? expiresAt;

  @override
  String toString() {
    return 'PlaybackSource(uri: [REDACTED], headers: [REDACTED], '
        'expiresAt: $expiresAt)';
  }
}

enum PlaybackFailureKind {
  emptyUrl,
  unsupportedScheme,
  invalidAddress,
  malformedToken,
  tokenExpiredAfterRefresh,
  unauthorizedAfterRefresh,
  timeout,
  cancelled,
  invalidPayload,
}

final class PlaybackFailure implements Exception {
  const PlaybackFailure(this.kind);

  final PlaybackFailureKind kind;

  @override
  String toString() => 'PlaybackFailure($kind)';
}
