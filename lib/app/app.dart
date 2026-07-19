import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/accessibility_preferences.dart';
import '../core/theme/cinema_theme.dart';
import 'router.dart';

export 'router.dart' show createAppRouter;

class GuoguoApp extends StatefulWidget {
  GuoguoApp({
    GoRouter? router,
    Stream<bool>? reduceTransparencyChanges,
    this.theme,
    super.key,
  }) : router = router ?? createAppRouter(),
       ownsRouter = router == null,
       reduceTransparencyChanges =
           reduceTransparencyChanges ??
           AccessibilityPreferences().reduceTransparencyChanges;

  final GoRouter router;
  final bool ownsRouter;
  final Stream<bool> reduceTransparencyChanges;
  final ThemeData? theme;

  @override
  State<GuoguoApp> createState() => _GuoguoAppState();
}

class _GuoguoAppState extends State<GuoguoApp> {
  @override
  void dispose() {
    if (widget.ownsRouter) {
      widget.router.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inheritedMediaQuery = MediaQuery.maybeOf(context);

    return StreamBuilder<bool>(
      stream: widget.reduceTransparencyChanges,
      initialData: false,
      builder: (context, snapshot) => MaterialApp.router(
        title: '果果',
        debugShowCheckedModeBanner: false,
        theme: widget.theme ?? CinemaTheme.dark(),
        darkTheme: widget.theme ?? CinemaTheme.dark(),
        themeMode: ThemeMode.dark,
        routerConfig: widget.router,
        builder: (context, child) {
          Widget result = AccessibilityPreferencesScope(
            reduceTransparency: snapshot.data ?? false,
            child: child ?? const SizedBox.shrink(),
          );
          if (inheritedMediaQuery != null) {
            result = MediaQuery(data: inheritedMediaQuery, child: result);
          }
          return result;
        },
      ),
    );
  }
}
