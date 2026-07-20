typedef MediaId = String;

enum MediaKind { movie, series, anime }

final class EpisodeRef {
  const EpisodeRef({
    required this.lineId,
    required this.episodeId,
    required this.title,
  });

  final String lineId;
  final String episodeId;
  final String title;
}

final class MediaSummary {
  const MediaSummary({
    required this.id,
    required this.title,
    required this.kind,
    required this.posterUrl,
    required this.year,
  });

  final MediaId id;
  final String title;
  final MediaKind kind;
  final Uri? posterUrl;
  final int? year;
}

final class MediaDetail {
  MediaDetail({
    required this.id,
    required this.title,
    required this.kind,
    required this.posterUrl,
    required this.year,
    required this.synopsis,
    required List<EpisodeRef> episodes,
  }) : episodes = List.unmodifiable(episodes);

  final MediaId id;
  final String title;
  final MediaKind kind;
  final Uri? posterUrl;
  final int? year;
  final String synopsis;
  final List<EpisodeRef> episodes;
}

final class SearchQuery {
  const SearchQuery({
    required this.term,
    this.kind,
    this.year,
    this.sort,
    this.cursor,
  });

  final String term;
  final MediaKind? kind;
  final int? year;
  final String? sort;
  final String? cursor;
}

final class Page<T> {
  Page({required List<T> items, required this.nextCursor})
    : items = List.unmodifiable(items);

  final List<T> items;
  final String? nextCursor;
}
