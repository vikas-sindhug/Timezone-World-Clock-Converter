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
      let appGroupId = "group.com.dharampal.worldclock"

      switch call.method {
      case "syncWidgetData":
        if let args = call.arguments as? [String: Any] {
          if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
            if let payloadJson = args["payload"] as? String {
              sharedDefaults.set(payloadJson, forKey: "world_clock_widget_data")
            }
            if let citiesJson = args["cities"] as? String {
              sharedDefaults.set(citiesJson, forKey: "world_clock_cities")
            }
            sharedDefaults.synchronize()
          }

          #if canImport(WidgetKit)
          if #available(macOS 11.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          #endif
          result(true)
        } else if let jsonString = call.arguments as? String {
          // Backward compatibility for direct string payload
          if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
            sharedDefaults.set(jsonString, forKey: "world_clock_widget_data")
            sharedDefaults.synchronize()
          }

          #if canImport(WidgetKit)
          if #available(macOS 11.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          #endif
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected JSON payload", details: nil))
        }

      case "reloadTimelines":
        #if canImport(WidgetKit)
        if #available(macOS 11.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
        result(true)

      case "getConfiguredWidgets":
        #if canImport(WidgetKit)
        if #available(macOS 11.0, *) {
          WidgetCenter.shared.getCurrentConfigurations { res in
            switch res {
            case .success(let widgetInfoList):
              let list: [[String: Any]] = widgetInfoList.map { info in
                var familyStr = "systemSmall"
                switch info.family {
                case .systemSmall: familyStr = "systemSmall"
                case .systemMedium: familyStr = "systemMedium"
                case .systemLarge: familyStr = "systemLarge"
                case .systemExtraLarge: familyStr = "systemExtraLarge"
                default: familyStr = "unknown"
                }

                var dict: [String: Any] = [
                  "kind": info.kind,
                  "family": familyStr
                ]
                #if canImport(AppIntents)
                if #available(macOS 14.0, *) {
                  if let config = info.configuration {
                    dict["description"] = String(describing: config)
                  }
                }
                #endif
                return dict
              }
              DispatchQueue.main.async {
                result(list)
              }
            case .failure(let error):
              DispatchQueue.main.async {
                result(FlutterError(code: "WIDGET_ERROR", message: error.localizedDescription, details: nil))
              }
            }
          }
        } else {
          result([])
        }
        #else
        result([])
        #endif

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  // Handle deep-link URLs (e.g. worldclock://city/tokyo_jp or worldclock://city/Asia/Tokyo)
  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      guard url.scheme == "worldclock" else { continue }

      // Check query items: worldclock://open?city=tokyo_jp
      if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
        if let cityParam = components.queryItems?.first(where: { $0.name == "city" || $0.name == "id" })?.value, !cityParam.isEmpty {
          widgetChannel?.invokeMethod("onDeepLinkCity", cityParam)
          continue
        }
      }

      // Check path components: worldclock://city/<id>
      let pathComponents = url.pathComponents.filter { $0 != "/" && $0 != "city" }
      if let cityId = pathComponents.last, !cityId.isEmpty {
        widgetChannel?.invokeMethod("onDeepLinkCity", cityId)
      } else if let host = url.host, host != "city" && !host.isEmpty {
        widgetChannel?.invokeMethod("onDeepLinkCity", host)
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
