import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guoguo/domain/media_item.dart';
import 'package:guoguo/ui/components/apple_glass_surface.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key, required this.items, required this.onOpen});

  final List<MediaItem> items;
  final ValueChanged<MediaItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 150),
        children: [
          const Text(
            '资源库',
            style: TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '收藏与本地媒体',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            AppleGlassSurface(
              borderRadius: 28,
              padding: const EdgeInsets.all(30),
              child: const Column(
                children: [
                  Icon(
                    CupertinoIcons.heart,
                    size: 42,
                    color: Color(0xFF007AFF),
                  ),
                  SizedBox(height: 14),
                  Text(
                    '还没有收藏',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '进入影片详情后点爱心即可加入资源库。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8E8E93), height: 1.4),
                  ),
                ],
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => onOpen(item),
                  child: AppleGlassSurface(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 78,
                            height: 104,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: item.colors),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_forward,
                          color: Color(0xFFAEAEB2),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
