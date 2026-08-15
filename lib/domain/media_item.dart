import 'package:flutter/material.dart';

class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.year,
    required this.colors,
    this.progress = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final String year;
  final List<Color> colors;
  final double progress;
}

const mockMediaCatalog = <MediaItem>[
  MediaItem(
    id: 'douluo2',
    title: '斗罗大陆 2',
    subtitle: '第 166 集 · 更新中',
    year: '2026',
    colors: [Color(0xFF30496F), Color(0xFFF2B58E)],
  ),
  MediaItem(
    id: 'mushenji',
    title: '牧神记',
    subtitle: 'S01 · E84 · 第 84 集',
    year: '2026',
    colors: [Color(0xFF222D4F), Color(0xFFE79B55)],
    progress: 0.42,
  ),
  MediaItem(
    id: 'yirenzhixia',
    title: '一人之下',
    subtitle: 'S06 · E24 · 第 24 集',
    year: '2026',
    colors: [Color(0xFF182337), Color(0xFF5C83C6)],
    progress: 0.18,
  ),
  MediaItem(
    id: 'taxidriver',
    title: '模范出租车',
    subtitle: '动作 · 犯罪',
    year: '2021',
    colors: [Color(0xFF251F1D), Color(0xFFB16D3A)],
  ),
  MediaItem(
    id: 'studygroup',
    title: '流氓读书会',
    subtitle: '校园 · 动作',
    year: '2025',
    colors: [Color(0xFFF3D783), Color(0xFFDA904B)],
  ),
  MediaItem(
    id: 'cheongdam',
    title: '清潭国际高中',
    subtitle: '校园 · 悬疑',
    year: '2023',
    colors: [Color(0xFF51617B), Color(0xFF8FA3C6)],
  ),
  MediaItem(
    id: 'dearx',
    title: '亲爱的X',
    subtitle: '剧情 · 爱情',
    year: '2025',
    colors: [Color(0xFF6C4A55), Color(0xFFD0A3A6)],
  ),
  MediaItem(
    id: 'signal',
    title: '信号',
    subtitle: '悬疑 · 犯罪',
    year: '2016',
    colors: [Color(0xFF2E4058), Color(0xFF7FA5C9)],
  ),
];
