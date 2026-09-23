import Cocoa
import FlutterMacOS
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
class AppDelegate: FlutterAppDelegate {
  private var widgetChannel: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.worldclock/widget_sync", binaryMessenger: controller.engine.binaryMessenger)
    self.widgetChannel = channel

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "syncWidgetData":
        if let jsonString = call.arguments as? String {
          let appGroupId = "group.com.worldclock.app"
          let payloadKey = "world_clock_widget_data"
          if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
            sharedDefaults.set(jsonString, forKey: payloadKey)
            sharedDefaults.synchronize()
          }

          #if canImport(WidgetKit)
          if #available(macOS 11.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          #endif
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected JSON string payload", details: nil))
        }

      case "reloadTimelines":
        #if canImport(WidgetKit)
        if #available(macOS 11.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  // Handle deep-link URLs (e.g. worldclock://city/tokyo_jp)
  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      guard url.scheme == "worldclock" else { continue }

      // Format: worldclock://city/<id>
      if url.host == "city" || url.pathComponents.contains("city") {
        let cityId = url.lastPathComponent
        if !cityId.isEmpty && cityId != "city" {
          widgetChannel?.invokeMethod("onDeepLinkCity", cityId)
        }
      }
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
