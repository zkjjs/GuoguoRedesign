import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guoguo/ui/components/apple_glass_surface.dart';

class GlassSearchBar extends StatelessWidget {
  const GlassSearchBar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppleGlassSurface(
        borderRadius: 26,
        blur: 24,
        fillOpacity: 0.68,
        shadowOpacity: 0.06,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: const SizedBox(
          height: 54,
          child: Row(
            children: [
              Icon(CupertinoIcons.search, color: Color(0xFF8E8E93), size: 21),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '搜索影片、番剧、演员',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(CupertinoIcons.mic_fill, color: Color(0xFF007AFF), size: 19),
            ],
          ),
        ),
      ),
    );
  }
}
