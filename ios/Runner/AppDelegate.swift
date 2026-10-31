import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var screenAwakeChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "SporkleScreenAwake") {
      let channel = FlutterMethodChannel(
        name: "sporkle/screen_awake", binaryMessenger: registrar.messenger())
      screenAwakeChannel = channel
      channel.setMethodCallHandler { call, result in
        guard call.method == "setEnabled" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let enabled = call.arguments as? Bool else {
          result(FlutterError(code: "invalid-argument", message: "Expected a boolean", details: nil))
          return
        }
        UIApplication.shared.isIdleTimerDisabled = enabled
        result(nil)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
