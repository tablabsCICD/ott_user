import Flutter
import UIKit

@UIApplicationMain @objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let antiPiracyChannel = "com.filmytell.ott/anti_piracy"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAntiPiracyChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  private func registerAntiPiracyChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: antiPiracyChannel, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "Delegate deallocated", details: nil))
        return
      }

      switch call.method {
      case "setScreenCaptureProtection":
        result(nil)
      case "deviceIntegrity":
        result([
          "rooted": false,
          "jailbroken": self.isJailbrokenDevice(),
          "emulator": self.isSimulator(),
          "screenCaptured": UIScreen.main.isCaptured
        ])
      case "deviceIdentity":
        result([
          "deviceName": UIDevice.current.model,
          "osVersion": "iOS \(UIDevice.current.systemVersion)"
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func isJailbrokenDevice() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    let paths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/private/var/lib/apt/"
    ]

    for path in paths {
      if FileManager.default.fileExists(atPath: path) {
        return true
      }
    }

    let testPath = "/private/jailbreak_test_file.txt"
    do {
      try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
      try? FileManager.default.removeItem(atPath: testPath)
      return true
    } catch {
      return false
    }
    #endif
  }

  private func isSimulator() -> Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
  }
}
