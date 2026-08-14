import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guoguo/ui/components/apple_glass_surface.dart';

class FloatingGlassDock extends StatelessWidget {
  const FloatingGlassDock({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <({IconData icon, String label})>[
    (icon: CupertinoIcons.house_fill, label: '首页'),
    (icon: CupertinoIcons.rectangle_stack_fill, label: '资源库'),
    (icon: CupertinoIcons.clock_fill, label: '记录'),
    (icon: CupertinoIcons.search, label: '搜索'),
    (icon: CupertinoIcons.gear_alt_fill, label: '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppleGlassSurface(
      borderRadius: 999,
      blur: 30,
      fillOpacity: 0.78,
      shadowOpacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = selectedIndex == index;
            final color = selected
                ? const Color(0xFF007AFF)
                : const Color(0xFF8E8E93);

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.34)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: color, size: 23),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
