import 'package:flutter/widgets.dart';

@immutable
final class MotionPolicy {
  const MotionPolicy({required this.reduceMotion});

  factory MotionPolicy.fromMediaQuery(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MotionPolicy(
      reduceMotion:
          mediaQuery.disableAnimations || mediaQuery.accessibleNavigation,
    );
  }

  final bool reduceMotion;

  bool get usesFadeOnly => reduceMotion;

  Duration get transitionDuration => reduceMotion
      ? const Duration(milliseconds: 180)
      : const Duration(milliseconds: 400);
}
