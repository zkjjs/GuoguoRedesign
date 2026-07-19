import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _channelNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'channel');
final _searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');
final _favoritesNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'favorites',
);
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

GoRouter createAppRouter() => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/channel',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _channelNavigatorKey,
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
          navigatorKey: _searchNavigatorKey,
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
          navigatorKey: _favoritesNavigatorKey,
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
          navigatorKey: _profileNavigatorKey,
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
