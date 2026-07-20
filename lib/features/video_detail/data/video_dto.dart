import '../../../core/network/api_error.dart';

final class VideoListDto {
  const VideoListDto({required this.items, required this.nextCursor});

  factory VideoListDto.fromEnvelope(Object? payload) {
    final envelope = _map(payload);
    final data = _map(envelope['data']);
    final rawItems = data['list'];
    if (rawItems is! List<Object?>) {
      throw ApiError.invalidPayload;
    }

    return VideoListDto(
      items: List.unmodifiable(rawItems.map(VideoSummaryDto.fromJson)),
      nextCursor: _optionalString(data['next_cursor']),
    );
  }

  final List<VideoSummaryDto> items;
  final String? nextCursor;
}

final class VideoDetailDto {
  const VideoDetailDto({
    required this.id,
    required this.title,
    required this.kind,
    required this.poster,
    required this.year,
    required this.content,
    required this.lines,
  });

  factory VideoDetailDto.fromEnvelope(Object? payload) {
    final envelope = _map(payload);
    final data = _map(envelope['data']);
    final rawLines = data['vod_play_list'];
    if (rawLines != null && rawLines is! List<Object?>) {
      throw ApiError.invalidPayload;
    }

    return VideoDetailDto(
      id: data['vod_id'],
      title: data['vod_name'],
      kind: data['vod_type'],
      poster: data['vod_pic'],
      year: data['vod_year'],
      content: data['vod_content'],
      lines: List.unmodifiable(
        (rawLines as List<Object?>? ?? const <Object?>[]).map(
          EpisodeLineDto.fromJson,
        ),
      ),
    );
  }

  final Object? id;
  final Object? title;
  final Object? kind;
  final Object? poster;
  final Object? year;
  final Object? content;
  final List<EpisodeLineDto> lines;
}

final class VideoSummaryDto {
  const VideoSummaryDto({
    required this.id,
    required this.title,
    required this.kind,
    required this.poster,
    required this.year,
  });

  factory VideoSummaryDto.fromJson(Object? payload) {
    final json = _map(payload);
    return VideoSummaryDto(
      id: json['vod_id'],
      title: json['vod_name'],
      kind: json['vod_type'],
      poster: json['vod_pic'],
      year: json['vod_year'],
    );
  }

  final Object? id;
  final Object? title;
  final Object? kind;
  final Object? poster;
  final Object? year;
}

final class EpisodeLineDto {
  const EpisodeLineDto({required this.id, required this.episodes});

  factory EpisodeLineDto.fromJson(Object? payload) {
    final json = _map(payload);
    final rawEpisodes = json['episodes'];
    if (rawEpisodes is! List<Object?>) {
      throw ApiError.invalidPayload;
    }
    return EpisodeLineDto(
      id: json['line_id'],
      episodes: List.unmodifiable(rawEpisodes.map(EpisodeDto.fromJson)),
    );
  }

  final Object? id;
  final List<EpisodeDto> episodes;
}

final class EpisodeDto {
  const EpisodeDto({required this.id, required this.title});

  factory EpisodeDto.fromJson(Object? payload) {
    final json = _map(payload);
    return EpisodeDto(id: json['episode_id'], title: json['title']);
  }

  final Object? id;
  final Object? title;
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map<String, Object?>) {
    throw ApiError.invalidPayload;
  }
  return value;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is! String) throw ApiError.invalidPayload;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
