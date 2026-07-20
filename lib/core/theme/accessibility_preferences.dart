import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

final class AccessibilityPreferences {
  AccessibilityPreferences({EventChannel? channel})
    : _channel =
          channel ??
          const EventChannel(
            'com.example.dongmangongheguo/accessibility_preferences',
          );

  final EventChannel _channel;

  Stream<bool> get reduceTransparencyChanges => _channel
      .receiveBroadcastStream()
      .where((event) => event is bool)
      .cast<bool>()
      .distinct();
}

class AccessibilityPreferencesScope extends InheritedWidget {
  const AccessibilityPreferencesScope({
    required this.reduceTransparency,
    required super.child,
    super.key,
  });

  final bool reduceTransparency;

  static bool reduceTransparencyOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AccessibilityPreferencesScope>()
          ?.reduceTransparency ??
      false;

  @override
  bool updateShouldNotify(AccessibilityPreferencesScope oldWidget) =>
      reduceTransparency != oldWidget.reduceTransparency;
}
