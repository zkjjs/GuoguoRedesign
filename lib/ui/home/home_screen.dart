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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          SafeArea(
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
                  const GlassSearchBar(),
                  const SizedBox(height: 20),
                  const HeroMediaCard(),
                  const SizedBox(height: 28),
                  MediaShelf(
                    title: '继续观看',
                    trailing: '7 ›',
                    child: SizedBox(
                      height: 232,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: const [
                          ContinueWatchingCard(
                            title: '牧神记',
                            subtitle: 'S01 · E84 · 第 84 集',
                            progress: 0.42,
                            colors: [Color(0xFF222D4F), Color(0xFFE79B55)],
                          ),
                          SizedBox(width: 14),
                          ContinueWatchingCard(
                            title: '一人之下',
                            subtitle: 'S06 · E24 · 第 24 集',
                            progress: 0.18,
                            colors: [Color(0xFF182337), Color(0xFF5C83C6)],
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
                        const SizedBox(width: 14),
                        Expanded(
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
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => _PosterCard(index: index),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: FloatingGlassDock(
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
            ),
          ),
        ],
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
  const _PosterCard({required this.index});

  final int index;

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
    return SizedBox(
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }
}
