final class PlaybackRequest {
  const PlaybackRequest({
    required this.mediaId,
    required this.lineId,
    required this.episodeId,
  });

  final String mediaId;
  final String lineId;
  final String episodeId;
}

final class PlaybackContext {
  const PlaybackContext({
    required this.mediaId,
    required this.lineId,
    required this.episodeId,
  });

  factory PlaybackContext.fromRequest(PlaybackRequest request) {
    return PlaybackContext(
      mediaId: request.mediaId,
      lineId: request.lineId,
      episodeId: request.episodeId,
    );
  }

  final String mediaId;
  final String lineId;
  final String episodeId;
}
