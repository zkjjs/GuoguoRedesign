import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell.dart';

GoRouter createAppRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final channelNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'channel');
  final searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');
  final favoritesNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'favorites',
  );
  final profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/channel',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: channelNavigatorKey,
            routes: [
              GoRoute(
                path: '/channel',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BranchLandingPage(
                    title: '频道',
                    icon: Icons.live_tv_rounded,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: searchNavigatorKey,
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BranchLandingPage(
                    title: '搜索',
                    icon: Icons.search_rounded,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: favoritesNavigatorKey,
            routes: [
              GoRoute(
                path: '/favorites',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BranchLandingPage(
                    title: '收藏',
                    icon: Icons.bookmark_rounded,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BranchLandingPage(
                    title: '我的',
                    icon: Icons.person_rounded,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
