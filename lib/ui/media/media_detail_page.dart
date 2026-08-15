import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guoguo/domain/media_item.dart';
import 'package:guoguo/ui/components/apple_glass_surface.dart';

class MediaDetailPage extends StatelessWidget {
  const MediaDetailPage({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onPlay,
  });

  final MediaItem item;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(CupertinoIcons.back),
                ),
                const SizedBox(width: 8),
                const Text(
                  '影片详情',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: AspectRatio(
                aspectRatio: 1.65,
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
            const SizedBox(height: 20),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${item.year} · ${item.subtitle}',
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(22),
                    onPressed: onPlay,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.play_fill, size: 18),
                        SizedBox(width: 8),
                        Text('开始播放'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onToggleFavorite,
                  child: AppleGlassSurface(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      isFavorite
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      color: isFavorite
                          ? const Color(0xFFFF375F)
                          : const Color(0xFF007AFF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppleGlassSurface(
              borderRadius: 28,
              padding: const EdgeInsets.all(20),
              child: const Text(
                '这是新版详情页。下一阶段会把这里接到原应用的视频详情、分集、播放地址与弹幕接口。',
                style: TextStyle(
                  color: Color(0xFF636366),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
