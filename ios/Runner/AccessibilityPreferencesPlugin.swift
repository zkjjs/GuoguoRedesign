import Flutter
import UIKit

final class AccessibilityPreferencesPlugin: NSObject, FlutterStreamHandler {
  private static let channelName =
    "com.example.dongmangongheguo/accessibility_preferences"

  private var eventSink: FlutterEventSink?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterEventChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = AccessibilityPreferencesPlugin()
    channel.setStreamHandler(instance)
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(reduceTransparencyDidChange),
      name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
      object: nil
    )
    events(UIAccessibility.isReduceTransparencyEnabled)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(
      self,
      name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
      object: nil
    )
    eventSink = nil
    return nil
  }

  @objc private func reduceTransparencyDidChange() {
    eventSink?(UIAccessibility.isReduceTransparencyEnabled)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
