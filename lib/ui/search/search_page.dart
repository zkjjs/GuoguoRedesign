import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guoguo/domain/media_item.dart';
import 'package:guoguo/ui/components/apple_glass_surface.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.onOpen});

  final ValueChanged<MediaItem> onOpen;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final results = normalized.isEmpty
        ? mockMediaCatalog
        : mockMediaCatalog
            .where(
              (item) =>
                  item.title.toLowerCase().contains(normalized) ||
                  item.subtitle.toLowerCase().contains(normalized) ||
                  item.year.contains(normalized),
            )
            .toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 150),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: CupertinoSearchTextField(
              autofocus: false,
              placeholder: '影片、番剧、演员',
              backgroundColor: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            normalized.isEmpty ? '推荐内容' : '搜索结果 · ${results.length}',
            style: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 56),
              child: Center(
                child: Text(
                  '没有找到相关内容',
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
                ),
              ),
            )
          else
            ...results.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onOpen(item),
                  child: AppleGlassSurface(
                    borderRadius: 24,
                    fillOpacity: 0.70,
                    shadowOpacity: 0.05,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 82,
                            height: 108,
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Color(0xFF1C1C1E),
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
                              const SizedBox(height: 5),
                              Text(
                                item.year,
                                style: const TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 12,
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
