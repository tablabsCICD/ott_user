import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let antiPiracyChannel = "com.filmytell.ott/anti_piracy"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerAntiPiracyChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerAntiPiracyChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: antiPiracyChannel,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "enableSecureScreen":
        result(nil)
      case "disableSecureScreen":
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
    let suspiciousPaths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/private/var/lib/apt/"
    ]

    if suspiciousPaths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
      return true
    }

    let probe = "/private/jailbreak_probe.txt"
    do {
      try "probe".write(toFile: probe, atomically: true, encoding: .utf8)
      try FileManager.default.removeItem(atPath: probe)
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
