import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guoguo/ui/components/apple_glass_surface.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.autoplay,
    required this.highQuality,
    required this.onAutoplayChanged,
    required this.onHighQualityChanged,
  });

  final bool autoplay;
  final bool highQuality;
  final ValueChanged<bool> onAutoplayChanged;
  final ValueChanged<bool> onHighQualityChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 150),
        children: [
          const Text(
            '设置',
            style: TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '播放、画质与应用设置',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          AppleGlassSurface(
            borderRadius: 28,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              children: [
                _SettingRow(
                  icon: CupertinoIcons.play_circle,
                  title: '自动播放',
                  subtitle: '进入播放页后自动开始',
                  value: autoplay,
                  onChanged: onAutoplayChanged,
                ),
                const Divider(height: 1, color: Color(0x22000000)),
                _SettingRow(
                  icon: CupertinoIcons.hifispeaker,
                  title: '优先高清',
                  subtitle: '网络允许时优先选择高画质',
                  value: highQuality,
                  onChanged: onHighQualityChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppleGlassSurface(
            borderRadius: 28,
            padding: const EdgeInsets.all(18),
            child: const Row(
              children: [
                Icon(CupertinoIcons.info_circle, color: Color(0xFF007AFF)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Guoguo Redesign · Apple Glass UI',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '1.0',
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF007AFF), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
