import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guoguo/domain/media_item.dart';
import 'package:guoguo/ui/components/apple_glass_surface.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.items, required this.onOpen});

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
            '观看记录',
            style: TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '最近看过的内容',
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
                    CupertinoIcons.clock,
                    size: 42,
                    color: Color(0xFF007AFF),
                  ),
                  SizedBox(height: 14),
                  Text(
                    '暂无观看记录',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '在详情页点击“开始播放”后会记录在这里。',
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
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: item.colors),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            CupertinoIcons.play_fill,
                            color: Colors.white,
                            size: 20,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
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
