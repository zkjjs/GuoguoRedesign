import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guoguo/ui/components/apple_glass_surface.dart';
import 'package:guoguo/ui/home/widgets/continue_watching_card.dart';
import 'package:guoguo/ui/home/widgets/floating_glass_dock.dart';
import 'package:guoguo/ui/home/widgets/glass_search_bar.dart';
import 'package:guoguo/ui/home/widgets/hero_media_card.dart';
import 'package:guoguo/ui/home/widgets/media_shelf.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showMediaDetail(String title) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        message: const Text('详情页与真实播放接口正在接入。现在这个入口已经可以正常响应点击。'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('播放'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('查看详情'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ),
    );
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
        return const _DestinationPage(
          title: '资源库',
          subtitle: '收藏与本地媒体',
          icon: CupertinoIcons.rectangle_stack_fill,
        );
      case 2:
        return const _DestinationPage(
          title: '观看记录',
          subtitle: '最近看过的内容',
          icon: CupertinoIcons.clock_fill,
        );
      case 3:
        return const _SearchDestinationPage();
      case 4:
        return const _DestinationPage(
          title: '设置',
          subtitle: '播放、画质与应用设置',
          icon: CupertinoIcons.gear_alt_fill,
        );
      default:
        return _HomeContent(
          onSearch: () => _selectDestination(3),
          onMediaTap: _showMediaDetail,
        );
    }
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.onSearch, required this.onMediaTap});

  final VoidCallback onSearch;
  final ValueChanged<String> onMediaTap;

  @override
  Widget build(BuildContext context) {
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
            HeroMediaCard(onPlay: () => onMediaTap('斗罗大陆 2')),
            const SizedBox(height: 28),
            MediaShelf(
              title: '继续观看',
              trailing: '7 ›',
              child: SizedBox(
                height: 232,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ContinueWatchingCard(
                      title: '牧神记',
                      subtitle: 'S01 · E84 · 第 84 集',
                      progress: 0.42,
                      colors: const [Color(0xFF222D4F), Color(0xFFE79B55)],
                      onTap: () => onMediaTap('牧神记'),
                    ),
                    const SizedBox(width: 14),
                    ContinueWatchingCard(
                      title: '一人之下',
                      subtitle: 'S06 · E24 · 第 24 集',
                      progress: 0.18,
                      colors: const [Color(0xFF182337), Color(0xFF5C83C6)],
                      onTap: () => onMediaTap('一人之下'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            MediaShelf(
              title: '我的媒体',
              trailing: '17 ›',
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onMediaTap('播放列表'),
                      child: AppleGlassSurface(
                        borderRadius: 26,
                        fillOpacity: 0.72,
                        shadowOpacity: 0.07,
                        padding: const EdgeInsets.all(18),
                        child: const SizedBox(
                          height: 128,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.play_circle,
                                color: Color(0xFFAEAEB2),
                                size: 48,
                              ),
                              SizedBox(height: 12),
                              Text(
                                '播放列表',
                                style: TextStyle(
                                  color: Color(0xFF1C1C1E),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onMediaTap('我的媒体'),
                      child: AppleGlassSurface(
                        borderRadius: 26,
                        fillOpacity: 0.68,
                        shadowOpacity: 0.07,
                        padding: const EdgeInsets.all(14),
                        child: const SizedBox(
                          height: 136,
                          child: _MiniPosterStrip(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            MediaShelf(
              title: '电视 · 韩国',
              trailing: '45 ›',
              child: SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: 5,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) => _PosterCard(
                    index: index,
                    onTap: () => onMediaTap(_PosterCard.titles[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationPage extends StatelessWidget {
  const _DestinationPage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            AppleGlassSurface(
              borderRadius: 30,
              padding: const EdgeInsets.all(28),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Icon(icon, size: 46, color: const Color(0xFF007AFF)),
                    const SizedBox(height: 16),
                    Text(
                      '$title 页面已连接',
                      style: const TextStyle(
                        color: Color(0xFF1C1C1E),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '下一步会接入原应用的真实数据与业务逻辑。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchDestinationPage extends StatelessWidget {
  const _SearchDestinationPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '搜索内容',
              style: TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 18),
            AppleGlassSurface(
              borderRadius: 28,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const SizedBox(
                height: 58,
                child: Row(
                  children: [
                    Icon(CupertinoIcons.search, color: Color(0xFF8E8E93)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '影片、番剧、演员',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
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

class _MiniPosterStrip extends StatelessWidget {
  const _MiniPosterStrip();

  @override
  Widget build(BuildContext context) {
    const gradients = [
      [Color(0xFF2E384E), Color(0xFF9D6554)],
      [Color(0xFF364559), Color(0xFFD59B45)],
      [Color(0xFF40516B), Color(0xFF7A88A9)],
    ];

    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradients[index],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.index, this.onTap});

  final int index;
  final VoidCallback? onTap;

  static const titles = ['模范出租车', '流氓读书会', '清潭国际高中', '亲爱的X', '信号'];
  static const years = ['2021', '2025', '2023', '2025', '2016'];
  static const colors = [
    [Color(0xFF251F1D), Color(0xFFB16D3A)],
    [Color(0xFFF3D783), Color(0xFFDA904B)],
    [Color(0xFF51617B), Color(0xFF8FA3C6)],
    [Color(0xFF6C4A55), Color(0xFFD0A3A6)],
    [Color(0xFF2E4058), Color(0xFF7FA5C9)],
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
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
                      colors: colors[index],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${10 + index * 10}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              titles[index],
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
              years[index],
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
