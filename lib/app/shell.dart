import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/cinema_tokens.dart';
import '../core/theme/glass_surface.dart';
import '../core/theme/motion_policy.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _selectBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final motion = MotionPolicy.fromMediaQuery(context);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: GlassSurface(
        child: SafeArea(
          top: false,
          child: NavigationBar(
            animationDuration: motion.transitionDuration,
            height: CinemaTokens.navHeight,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _selectBranch,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.live_tv_outlined),
                selectedIcon: Icon(Icons.live_tv_rounded),
                label: '频道',
              ),
              NavigationDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search_rounded),
                label: '搜索',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border),
                selectedIcon: Icon(Icons.bookmark_rounded),
                label: '收藏',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: '我的',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BranchLandingPage extends StatelessWidget {
  const BranchLandingPage({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        child: Align(
          alignment: Alignment.topLeft,
          child: Semantics(
            header: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: CinemaTokens.accent, size: 28),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
