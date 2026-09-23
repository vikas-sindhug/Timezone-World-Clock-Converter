import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Handles deep linking from macOS Desktop Widgets into the Flutter application.
/// URL format: `worldclock://city/<city_id>`
class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('com.worldclock/widget_sync');

  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;

  DeepLinkService._internal() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final ValueNotifier<String?> deepLinkedCityId = ValueNotifier<String?>(null);

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeepLinkCity':
        final cityId = call.arguments as String?;
        if (cityId != null && cityId.isNotEmpty) {
          debugPrint('[DeepLinkService] Received deep link for city: $cityId');
          deepLinkedCityId.value = cityId;
        }
        return true;
      default:
        return null;
    }
  }

  void clearDeepLink() {
    deepLinkedCityId.value = null;
  }
}
