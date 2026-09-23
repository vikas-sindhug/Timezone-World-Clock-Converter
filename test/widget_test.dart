import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:world_clock/core/time/timezone_engine.dart';
import 'package:world_clock/data/repositories/city_database.dart';
import 'package:world_clock/data/repositories/settings_repository.dart';
import 'package:world_clock/main.dart';
import 'package:world_clock/presentation/dashboard/clock_card.dart';
import 'package:world_clock/state/clock_state.dart';
import 'package:world_clock/state/converter_state.dart';
import 'package:world_clock/state/meeting_planner_state.dart';
import 'package:world_clock/state/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_clock/state/widget_state.dart';

Widget _buildApp({
  required SettingsState settingsState,
  required ClockState clockState,
  required ConverterState converterState,
  required MeetingPlannerState meetingPlannerState,
  DesktopWidgetState? widgetState,
}) {
  if (clockState.cities.isEmpty) {
    for (final id in SettingsRepository.defaultCityIds) {
      final c = CityDatabase.findById(id);
      if (c != null) clockState.addCity(c);
    }
  }
  final ws = widgetState ?? DesktopWidgetState();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsState>.value(value: settingsState),
      ChangeNotifierProvider<ClockState>.value(value: clockState),
      ChangeNotifierProvider<ConverterState>.value(value: converterState),
      ChangeNotifierProvider<MeetingPlannerState>.value(value: meetingPlannerState),
      ChangeNotifierProvider<DesktopWidgetState>.value(value: ws),
    ],
    child: const WorldClockApp(),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await TimezoneEngine.initialize();
  });

  testWidgets('WorldClockApp renders navigation and main view', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final settingsState = SettingsState();
    final clockState = ClockState();
    final converterState = ConverterState();
    final meetingPlannerState = MeetingPlannerState();

    await tester.pumpWidget(
      _buildApp(
        settingsState: settingsState,
        clockState: clockState,
        converterState: converterState,
        meetingPlannerState: meetingPlannerState,
      ),
    );
    await tester.pumpAndSettle();

    // Verify main app branding is displayed
    expect(find.text('WorldClock'), findsWidgets);
    expect(find.text('World Clocks'), findsOneWidget);
    expect(find.text('World Map'), findsOneWidget);
    expect(find.text('Time Converter'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    clockState.dispose();
  });

  final testResolutions = <Size>[
    const Size(1024, 600), // Compact netbook / narrow window
    const Size(1280, 720), // 720p HD
    const Size(1280, 800), // 16:10 Laptop
    const Size(1366, 768), // Standard laptop
    const Size(1440, 900), // MacBook Pro standard
    const Size(1600, 900), // Desktop 900p
    const Size(1920, 1080), // 1080p FHD
    const Size(2560, 1440), // 2K QHD
  ];

  for (final size in testResolutions) {
    testWidgets('Dashboard renders zero overflow at ${size.width.toInt()}x${size.height.toInt()}', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final settingsState = SettingsState();
      final clockState = ClockState();
      final converterState = ConverterState();
      final meetingPlannerState = MeetingPlannerState();

      await tester.pumpWidget(
        _buildApp(
          settingsState: settingsState,
          clockState: clockState,
          converterState: converterState,
          meetingPlannerState: meetingPlannerState,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClockCard), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      clockState.dispose();
    });
  }

  final testDpiScales = [1.25, 1.5, 2.0];
  for (final scale in testDpiScales) {
    testWidgets('Dashboard renders zero overflow at 1920x1080 with ${scale * 100}% DPI', (WidgetTester tester) async {
      tester.view.physicalSize = Size(1920 * scale, 1080 * scale);
      tester.view.devicePixelRatio = scale;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final settingsState = SettingsState();
      final clockState = ClockState();
      final converterState = ConverterState();
      final meetingPlannerState = MeetingPlannerState();

      await tester.pumpWidget(
        _buildApp(
          settingsState: settingsState,
          clockState: clockState,
          converterState: converterState,
          meetingPlannerState: meetingPlannerState,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClockCard), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      clockState.dispose();
    });
  }

  testWidgets('All navigation tabs render with zero overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final settingsState = SettingsState();
    final clockState = ClockState();
    final converterState = ConverterState();
    final meetingPlannerState = MeetingPlannerState();

    await tester.pumpWidget(
      _buildApp(
        settingsState: settingsState,
        clockState: clockState,
        converterState: converterState,
        meetingPlannerState: meetingPlannerState,
      ),
    );
    await tester.pumpAndSettle();

    final navTabs = [
      'World Map',
      'Time Converter',
      'Time Difference',
      'Meeting Planner',
      'World Timeline',
      'Desktop Widgets',
      'World Clocks',
    ];

    for (final tab in navTabs) {
      final tabFinder = find.text(tab);
      expect(tabFinder, findsWidgets);
      await tester.ensureVisible(tabFinder.first);
      await tester.pumpAndSettle();
      await tester.tap(tabFinder.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow occurred when navigating to $tab');
    }

    await tester.pumpWidget(const SizedBox());
    clockState.dispose();
  });

  testWidgets('ClockCard renders cleanly without vertical or horizontal overflow at various widths', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testCities = [
      CityDatabase.findById('tokyo_jp')!,
      CityDatabase.findById('london_gb')!,
      CityDatabase.findById('new_york_us')!,
      CityDatabase.findById('dubai_ae')!,
      CityDatabase.findById('jaipur_in')!,
      CityDatabase.findById('honolulu_us')!,
      CityDatabase.findById('kathmandu_np')!,
    ];

    final clockState = ClockState();
    for (final c in testCities) {
      clockState.addCity(c);
    }
    final cards = clockState.clockCards;
    final widths = [280.0, 320.0, 360.0, 420.0, 500.0];

    for (final card in cards) {
      for (final width in widths) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: ClockCard(
                    data: card,
                    is24Hour: false,
                    showSeconds: true,
                    showAnalogClock: true,
                    onToggleFavorite: () {},
                    onRemove: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'Overflow in ClockCard for ${card.city.name} at width $width');
      }
    }

    await tester.pumpWidget(const SizedBox());
    clockState.dispose();
  });
}
