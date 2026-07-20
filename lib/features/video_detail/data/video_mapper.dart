import '../../../core/network/api_error.dart';
import '../domain/media_models.dart';
import 'video_dto.dart';

final class VideoMapper {
  const VideoMapper();

  Page<MediaSummary> mapListEnvelope(Object? payload) {
    final dto = VideoListDto.fromEnvelope(payload);
    return Page(
      items: List.unmodifiable(dto.items.map(_summary)),
      nextCursor: dto.nextCursor,
    );
  }

  MediaDetail mapDetailEnvelope(Object? payload) {
    final dto = VideoDetailDto.fromEnvelope(payload);
    final identity = _identity(dto.id);
    final title = _requiredText(dto.title);

    return MediaDetail(
      id: identity,
      title: title,
      kind: _kind(dto.kind),
      posterUrl: _uri(dto.poster),
      year: _year(dto.year),
      synopsis: _optionalText(dto.content) ?? '',
      episodes: List.unmodifiable(
        dto.lines
            .where((line) => line.episodes.isNotEmpty)
            .expand(
              (line) => line.episodes.map(
                (episode) => EpisodeRef(
                  lineId: _identity(line.id),
                  episodeId: _identity(episode.id),
                  title: _requiredText(episode.title),
                ),
              ),
            ),
      ),
    );
  }

  MediaSummary _summary(VideoSummaryDto dto) => MediaSummary(
    id: _identity(dto.id),
    title: _requiredText(dto.title),
    kind: _kind(dto.kind),
    posterUrl: _uri(dto.poster),
    year: _year(dto.year),
  );

  String _identity(Object? value) {
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) return normalized;
    } else if (value is num &&
        value.isFinite &&
        value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    throw ApiError.invalidPayload;
  }

  String _requiredText(Object? value) {
    final normalized = _optionalText(value);
    if (normalized == null) throw ApiError.invalidPayload;
    return normalized;
  }

  String? _optionalText(Object? value) {
    if (value == null) return null;
    if (value is! String) throw ApiError.invalidPayload;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  MediaKind _kind(Object? value) => switch (value) {
    'series' || 2 => MediaKind.series,
    'anime' || 3 => MediaKind.anime,
    _ => MediaKind.movie,
  };

  Uri? _uri(Object? value) {
    final normalized = _optionalText(value);
    return normalized == null ? null : Uri.tryParse(normalized);
  }

  int? _year(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
