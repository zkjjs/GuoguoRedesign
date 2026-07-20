import 'playback_request.dart';
import 'playback_source.dart';

abstract interface class PlaybackRepository {
  Future<PlaybackSource> resolve(PlaybackRequest request);
}
