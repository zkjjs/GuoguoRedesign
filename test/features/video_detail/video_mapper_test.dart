import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guoguo/core/network/api_error.dart';
import 'package:guoguo/features/channel/domain/channel_models.dart';
import 'package:guoguo/features/video_detail/data/video_mapper.dart';
import 'package:guoguo/features/video_detail/domain/media_models.dart';

Object? fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync());

void main() {
  const mapper = VideoMapper();

  group('video list mapping', () {
    test('normalizes numeric and string identities', () {
      final page = mapper.mapListEnvelope(fixture('video_list.json'));

      expect(page.items.map((item) => item.id), [
        '101',
        'series-202',
        'legacy-303',
      ]);
    });

    test('normalizes integral doubles to the integer identity spelling', () {
      final page = mapper.mapListEnvelope({
        'data': {
          'list': [
            {'vod_id': 101.0, 'vod_name': '整数浮点 ID'},
          ],
        },
      });

      expect(page.items.single.id, '101');
    });

    test('rejects fractional and non-finite numeric identities', () {
      for (final invalidId in [101.5, double.nan, double.infinity]) {
        expect(
          () => mapper.mapListEnvelope({
            'data': {
              'list': [
                {'vod_id': invalidId, 'vod_name': '无效 ID'},
              ],
            },
          }),
          throwsA(ApiError.invalidPayload),
          reason: '$invalidId must not become a media identity',
        );
      }
    });

    test('tolerates missing poster and absent year', () {
      final page = mapper.mapListEnvelope(fixture('video_list.json'));

      expect(page.items[1].posterUrl, isNull);
      expect(page.items[1].year, isNull);
      expect(page.items[2].year, isNull);
    });

    test('uses a stable fallback for an unknown media kind', () {
      final page = mapper.mapListEnvelope(fixture('video_list.json'));

      expect(page.items[2].kind, MediaKind.movie);
    });

    test('ignores unknown optional fields', () {
      final page = mapper.mapListEnvelope(fixture('video_list.json'));

      expect(page.items, hasLength(3));
      expect(page.nextCursor, 'page-2');
    });
  });

  group('video detail mapping', () {
    test('flattens episodes and ignores an empty episode line', () {
      final detail = mapper.mapDetailEnvelope(fixture('video_detail.json'));

      expect(detail.id, 'anime-404');
      expect(detail.kind, MediaKind.anime);
      expect(detail.episodes, hasLength(2));
      expect(detail.episodes.first.lineId, 'line-a');
      expect(detail.episodes.first.episodeId, '1');
      expect(detail.episodes.last.episodeId, 'ep-2');
    });

    test('rejects a malformed envelope', () {
      expect(
        () => mapper.mapListEnvelope({'code': 0, 'data': []}),
        throwsA(ApiError.invalidPayload),
      );
      expect(
        () => mapper.mapDetailEnvelope({'code': 0}),
        throwsA(ApiError.invalidPayload),
      );
    });

    test('rejects a missing required identity', () {
      expect(
        () => mapper.mapDetailEnvelope({
          'code': 0,
          'data': {'vod_name': '缺少 ID'},
        }),
        throwsA(ApiError.invalidPayload),
      );
      expect(
        () => mapper.mapDetailEnvelope({
          'code': 0,
          'data': {'vod_id': 1},
        }),
        throwsA(ApiError.invalidPayload),
      );
    });
  });

  group('domain collection immutability', () {
    const summary = MediaSummary(
      id: 'media-1',
      title: '作品',
      kind: MediaKind.movie,
      posterUrl: null,
      year: null,
    );
    const episode = EpisodeRef(
      lineId: 'line-1',
      episodeId: 'episode-1',
      title: '第一集',
    );

    test('MediaDetail defensively copies and protects episodes', () {
      final source = <EpisodeRef>[episode];
      final detail = MediaDetail(
        id: 'media-1',
        title: '作品',
        kind: MediaKind.movie,
        posterUrl: null,
        year: null,
        synopsis: '',
        episodes: source,
      );

      source.clear();

      expect(detail.episodes, [episode]);
      expect(() => detail.episodes.clear(), throwsUnsupportedError);
    });

    test('Page defensively copies and protects items', () {
      final source = <MediaSummary>[summary];
      final page = Page<MediaSummary>(items: source, nextCursor: null);

      source.clear();

      expect(page.items, [summary]);
      expect(() => page.items.clear(), throwsUnsupportedError);
    });

    test('ChannelSection defensively copies and protects items', () {
      final source = <MediaSummary>[summary];
      final section = ChannelSection(
        id: 'featured',
        title: '精选',
        items: source,
      );

      source.clear();

      expect(section.items, [summary]);
      expect(() => section.items.clear(), throwsUnsupportedError);
    });
  });
}
