import '../../channel/domain/channel_models.dart';
import 'media_models.dart';

abstract interface class VideoRepository {
  Future<MediaDetail> detail(MediaId id);

  Future<Page<MediaSummary>> search(SearchQuery query);

  Future<List<ChannelSection>> channelSections();
}
