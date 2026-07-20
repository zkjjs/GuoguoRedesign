import '../../video_detail/domain/media_models.dart';

final class ChannelSection {
  ChannelSection({
    required this.id,
    required this.title,
    required List<MediaSummary> items,
  }) : items = List.unmodifiable(items);

  final String id;
  final String title;
  final List<MediaSummary> items;
}
