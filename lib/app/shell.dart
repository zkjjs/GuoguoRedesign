import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/cinema_tokens.dart';
import '../core/theme/glass_surface.dart';
import '../core/theme/motion_policy.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _contentOpacity;

  @override
  void initState() {
    super.initState();
    _contentOpacity = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 180),
      animationBehavior: AnimationBehavior.preserve,
    );
  }

  @override
  void dispose() {
    _contentOpacity.dispose();
    super.dispose();
  }

  void _selectBranch(int index) {
    final motion = MotionPolicy.fromMediaQuery(context);
    final changingBranch = index != widget.navigationShell.currentIndex;

    if (motion.usesFadeOnly && changingBranch) {
      _contentOpacity
        ..duration = motion.transitionDuration
        ..forward(from: 0);
    }

    widget.navigationShell.goBranch(index, initialLocation: !changingBranch);
  }

  @override
  Widget build(BuildContext context) {
    final motion = MotionPolicy.fromMediaQuery(context);

    final body = motion.usesFadeOnly
        ? FadeTransition(
            key: const Key('reducedMotionBranchFade'),
            opacity: _contentOpacity,
            child: widget.navigationShell,
          )
        : widget.navigationShell;

    return Scaffold(
      extendBody: true,
      body: body,
      bottomNavigationBar: GlassSurface(
        child: SafeArea(
          top: false,
          child: NavigationBar(
            animationDuration: motion.usesFadeOnly
                ? Duration.zero
                : motion.transitionDuration,
            height: CinemaTokens.navHeight,
            selectedIndex: widget.navigationShell.currentIndex,
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
