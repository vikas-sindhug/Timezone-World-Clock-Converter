import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:world_clock/core/time/timezone_engine.dart';
import 'package:world_clock/data/models/widget_configuration.dart';
import 'package:world_clock/data/repositories/city_database.dart';
import 'package:world_clock/presentation/widgets/previews/analog_widget_preview.dart';
import 'package:world_clock/presentation/widgets/previews/large_widget_preview.dart';
import 'package:world_clock/presentation/widgets/previews/medium_widget_preview.dart';
import 'package:world_clock/presentation/widgets/previews/small_widget_preview.dart';
import 'package:world_clock/presentation/widgets/widgets_view.dart';
import 'package:world_clock/state/clock_state.dart';
import 'package:world_clock/state/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock/state/widget_state.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await TimezoneEngine.initialize();
  });

  group('WidgetConfiguration Unit Tests', () {
    test('Serializes to and from JSON correctly matching Swift Codable format', () {
      const config = WidgetConfiguration(
        singleCityId: 'tokyo_jp',
        multiCityIds: ['tokyo_jp', 'london_gb', 'new_york_us'],
        is24Hour: true,
        showSeconds: true,
        showAnalog: true,
        showUtcOffset: true,
        showDate: true,
        showDifferenceFromLocal: true,
        showDayNight: true,
        themeMode: 'dark',
      );

      final json = config.toJson();
      expect(json['singleCityId'], 'tokyo_jp');
      expect(json['multiCityIds'], ['tokyo_jp', 'london_gb', 'new_york_us']);
      expect(json['is24Hour'], true);
      expect(json['showSeconds'], true);
      expect(json['showAnalog'], true);
      expect(json['themeMode'], 'dark');

      final fromJson = WidgetConfiguration.fromJson(json);
      expect(fromJson.singleCityId, config.singleCityId);
      expect(fromJson.multiCityIds, config.multiCityIds);
      expect(fromJson.is24Hour, config.is24Hour);
      expect(fromJson.showSeconds, config.showSeconds);
      expect(fromJson.showAnalog, config.showAnalog);
      expect(fromJson.themeMode, config.themeMode);
    });

    test('Default values are set sensibly', () {
      const config = WidgetConfiguration();
      expect(config.singleCityId, isNull);
      expect(config.multiCityIds, isEmpty);
      expect(config.is24Hour, false);
      expect(config.showSeconds, false);
      expect(config.showAnalog, false);
      expect(config.showUtcOffset, true);
      expect(config.showDate, true);
      expect(config.themeMode, 'system');
    });
  });

  group('DesktopWidgetState Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default clocks when cities are provided', () async {
      final cities = [
        CityDatabase.findById('tokyo_jp')!,
        CityDatabase.findById('london_gb')!,
        CityDatabase.findById('new_york_us')!,
        CityDatabase.findById('jaipur_in')!,
      ];

      final state = DesktopWidgetState();
      await state.initialize(cities);

      expect(state.isInitialized, true);
      expect(state.singleCityId, 'tokyo_jp');
      expect(state.multiCityIds.length, 4);
      expect(state.getSelectedCity(cities)?.id, 'tokyo_jp');
      expect(state.getMultiCities(cities).length, 4);
    });

    test('Setting single city updates active state', () async {
      final cities = [
        CityDatabase.findById('tokyo_jp')!,
        CityDatabase.findById('london_gb')!,
      ];

      final state = DesktopWidgetState();
      await state.initialize(cities);

      await state.setSingleCity('london_gb', cities);
      expect(state.singleCityId, 'london_gb');
      expect(state.getSelectedCity(cities)?.id, 'london_gb');
    });

    test('Toggling multi-city respects min 2 and max 6 limits', () async {
      final cities = CityDatabase.allCities.take(8).toList();

      final state = DesktopWidgetState();
      await state.initialize(cities);

      // Initial has 4 cities
      expect(state.multiCityIds.length, 4);

      // Add 5th and 6th
      await state.toggleMultiCity(cities[4].id, cities);
      expect(state.multiCityIds.length, 5);
      await state.toggleMultiCity(cities[5].id, cities);
      expect(state.multiCityIds.length, 6);

      // Attempting to add 7th should be rejected (max 6)
      await state.toggleMultiCity(cities[6].id, cities);
      expect(state.multiCityIds.length, 6);

      // Remove down to 2
      await state.toggleMultiCity(cities[0].id, cities);
      await state.toggleMultiCity(cities[1].id, cities);
      await state.toggleMultiCity(cities[2].id, cities);
      await state.toggleMultiCity(cities[3].id, cities);
      expect(state.multiCityIds.length, 2);

      // Removing below 2 should be rejected (min 2)
      await state.toggleMultiCity(cities[4].id, cities);
      expect(state.multiCityIds.length, 2);
    });

    test('DesktopWidgetStatus accurately computes prepared vs configured status', () async {
      final cities = [
        CityDatabase.findById('tokyo_jp')!,
        CityDatabase.findById('london_gb')!,
      ];

      final state = DesktopWidgetState();
      await state.initialize(cities);

      // Default primary city is tokyo_jp, london_gb is in multiCityIds
      expect(
        state.getStatusForCity('tokyo_jp', 'Asia/Tokyo'),
        DesktopWidgetStatus.prepared,
      );
      expect(
        state.getStatusForCity('london_gb', 'Europe/London'),
        DesktopWidgetStatus.prepared,
      );
      // City not in single or multi is not configured
      expect(
        state.getStatusForCity('sydney_au', 'Australia/Sydney'),
        DesktopWidgetStatus.notConfigured,
      );
    });
  });

  group('WidgetKit Previews Zero-Overflow Tests', () {
    final tokyo = CityDatabase.findById('tokyo_jp')!;
    final sampleCities = [
      CityDatabase.findById('tokyo_jp')!,
      CityDatabase.findById('london_gb')!,
      CityDatabase.findById('new_york_us')!,
      CityDatabase.findById('jaipur_in')!,
    ];
    final testDate = DateTime.utc(2026, 9, 22, 12, 0, 0);

    testWidgets('SmallWidgetPreview renders cleanly without overflow (Digital & Analog)', (tester) async {
      const configDigital = WidgetConfiguration(
        showAnalog: false,
        showSeconds: false,
        showDate: true,
        showUtcOffset: true,
        showDayNight: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SmallWidgetPreview(
                city: tokyo,
                config: configDigital,
                nowUtc: testDate,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Tokyo'), findsOneWidget);
      expect(find.text('Japan'), findsOneWidget);

      // Test with Analog enabled
      const configAnalog = WidgetConfiguration(
        showAnalog: true,
        showSeconds: false,
        showDate: true,
        showUtcOffset: true,
        showDayNight: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SmallWidgetPreview(
                city: tokyo,
                config: configAnalog,
                nowUtc: testDate,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AnalogWidgetPreview), findsOneWidget);
    });

    testWidgets('MediumWidgetPreview renders cleanly without overflow', (tester) async {
      const config = WidgetConfiguration(
        showAnalog: true,
        showSeconds: true,
        showDate: true,
        showUtcOffset: true,
        showDifferenceFromLocal: true,
        showDayNight: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MediumWidgetPreview(
                city: tokyo,
                config: config,
                nowUtc: testDate,
                refTz: 'UTC',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Tokyo'), findsOneWidget);
      expect(find.byType(AnalogWidgetPreview), findsOneWidget);
    });

    testWidgets('LargeWidgetPreview renders multi-clocks cleanly without overflow', (tester) async {
      const config = WidgetConfiguration(
        is24Hour: false,
        showDayNight: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LargeWidgetPreview(
                cities: sampleCities,
                config: config,
                nowUtc: testDate,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('WORLD CLOCK'), findsOneWidget);
      expect(find.text('Tokyo'), findsOneWidget);
      expect(find.text('London'), findsOneWidget);
      expect(find.text('New York'), findsOneWidget);
      expect(find.text('Jaipur'), findsOneWidget);
    });

    testWidgets('WidgetsView renders full management page with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final clockState = ClockState();
      final settingsState = SettingsState();
      final widgetState = DesktopWidgetState();

      await clockState.load();
      await widgetState.initialize(clockState.cities);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ClockState>.value(value: clockState),
            ChangeNotifierProvider<SettingsState>.value(value: settingsState),
            ChangeNotifierProvider<DesktopWidgetState>.value(value: widgetState),
          ],
          child: const MaterialApp(
            home: WidgetsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('macOS Desktop Widgets'), findsOneWidget);
      expect(find.text('Live Widget Preview'), findsOneWidget);
      expect(find.text('Available Desktop Widgets'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      clockState.dispose();
    });
  });
}
