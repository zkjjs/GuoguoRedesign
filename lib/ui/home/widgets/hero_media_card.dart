import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guoguo/ui/components/apple_glass_surface.dart';

class HeroMediaCard extends StatelessWidget {
  const HeroMediaCard({super.key, this.onPlay});

  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF30496F),
                    Color(0xFF7BA3D8),
                    Color(0xFFF2B58E),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -30,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: AppleGlassSurface(
                borderRadius: 24,
                blur: 22,
                fillOpacity: 0.28,
                shadowOpacity: 0.04,
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '斗罗大陆 2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '第 166 集 · 更新中',
                            style: TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onPlay,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.play_fill,
                          color: Color(0xFF007AFF),
                          size: 21,
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
