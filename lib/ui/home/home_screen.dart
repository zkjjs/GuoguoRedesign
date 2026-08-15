import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guoguo/domain/media_item.dart';
import 'package:guoguo/ui/components/apple_glass_surface.dart';
import 'package:guoguo/ui/history/history_page.dart';
import 'package:guoguo/ui/home/widgets/continue_watching_card.dart';
import 'package:guoguo/ui/home/widgets/floating_glass_dock.dart';
import 'package:guoguo/ui/home/widgets/glass_search_bar.dart';
import 'package:guoguo/ui/home/widgets/hero_media_card.dart';
import 'package:guoguo/ui/home/widgets/media_shelf.dart';
import 'package:guoguo/ui/library/library_page.dart';
import 'package:guoguo/ui/media/media_detail_page.dart';
import 'package:guoguo/ui/search/search_page.dart';
import 'package:guoguo/ui/settings/settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final Set<String> _favoriteIds = <String>{};
  final List<String> _historyIds = <String>[];
  bool _autoplay = true;
  bool _highQuality = true;

  List<MediaItem> get _favorites => mockMediaCatalog
      .where((item) => _favoriteIds.contains(item.id))
      .toList(growable: false);

  List<MediaItem> get _history => _historyIds
      .map((id) => mockMediaCatalog.firstWhere((item) => item.id == id))
      .toList(growable: false);

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _openMedia(MediaItem item) async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute(
        builder: (context) => MediaDetailPage(
          item: item,
          isFavorite: _favoriteIds.contains(item.id),
          onToggleFavorite: () {
            setState(() {
              if (!_favoriteIds.add(item.id)) {
                _favoriteIds.remove(item.id);
              }
            });
            Navigator.of(context).pop();
            _openMedia(item);
          },
          onPlay: () {
            setState(() {
              _historyIds.remove(item.id);
              _historyIds.insert(0, item.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.title} 已加入观看记录，真实播放器下一步接入'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          Positioned.fill(child: _buildSelectedPage()),
          Positioned(
            left: 18,
            right: 18,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: FloatingGlassDock(
                selectedIndex: _selectedIndex,
                onSelected: _selectDestination,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPage() {
    switch (_selectedIndex) {
      case 1:
        return LibraryPage(items: _favorites, onOpen: _openMedia);
      case 2:
        return HistoryPage(items: _history, onOpen: _openMedia);
      case 3:
        return SearchPage(onOpen: _openMedia);
      case 4:
        return SettingsPage(
          autoplay: _autoplay,
          highQuality: _highQuality,
          onAutoplayChanged: (value) => setState(() => _autoplay = value),
          onHighQualityChanged: (value) =>
              setState(() => _highQuality = value),
        );
      default:
        return _HomeContent(
          onSearch: () => _selectDestination(3),
          onOpen: _openMedia,
        );
    }
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.onSearch, required this.onOpen});

  final VoidCallback onSearch;
  final ValueChanged<MediaItem> onOpen;

  MediaItem _item(String id) =>
      mockMediaCatalog.firstWhere((item) => item.id == id);

  @override
  Widget build(BuildContext context) {
    final continueItems = [_item('mushenji'), _item('yirenzhixia')];
    final posters = mockMediaCatalog.skip(3).toList(growable: false);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '首页',
              style: TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '发现值得看的内容',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            GlassSearchBar(onTap: onSearch),
            const SizedBox(height: 20),
            HeroMediaCard(onPlay: () => onOpen(_item('douluo2'))),
            const SizedBox(height: 28),
            MediaShelf(
              title: '继续观看',
              trailing: '${continueItems.length} ›',
              child: SizedBox(
                height: 232,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: continueItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final item = continueItems[index];
                    return ContinueWatchingCard(
                      title: item.title,
                      subtitle: item.subtitle,
                      progress: item.progress,
                      colors: item.colors,
                      onTap: () => onOpen(item),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            MediaShelf(
              title: '我的媒体',
              trailing: '入口 ›',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSearch,
                child: AppleGlassSurface(
                  borderRadius: 28,
                  fillOpacity: 0.70,
                  shadowOpacity: 0.06,
                  padding: const EdgeInsets.all(18),
                  child: const Row(
                    children: [
                      Icon(
                        CupertinoIcons.rectangle_stack_fill,
                        color: Color(0xFF007AFF),
                        size: 32,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '浏览全部内容',
                              style: TextStyle(
                                color: Color(0xFF1C1C1E),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '搜索、收藏和打开详情页',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_forward,
                        color: Color(0xFFAEAEB2),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            MediaShelf(
              title: '电视 · 韩国',
              trailing: '${posters.length} ›',
              child: SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: posters.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _PosterCard(item: posters[index], onTap: onOpen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.item, required this.onTap});

  final MediaItem item;
  final ValueChanged<MediaItem> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(item),
      child: SizedBox(
        width: 142,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 0.72,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item.colors,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.year,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -90,
            top: 40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8CC8FF).withValues(alpha: 0.20),
              ),
            ),
          ),
          Positioned(
            right: -70,
            top: 130,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFC3D5).withValues(alpha: 0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
