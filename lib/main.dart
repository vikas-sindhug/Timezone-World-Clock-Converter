import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/time/timezone_engine.dart';
import 'presentation/navigation/desktop_scaffold.dart';
import 'state/clock_state.dart';
import 'state/converter_state.dart';
import 'state/meeting_planner_state.dart';
import 'state/settings_state.dart';
import 'state/widget_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize IANA timezone database and system timezone detection
  await TimezoneEngine.initialize();

  // Initialize settings & clock states
  final settingsState = SettingsState();
  await settingsState.load();

  final clockState = ClockState();
  if (settingsState.referenceTimezone != null) {
    clockState.setReferenceTimezone(settingsState.referenceTimezone);
  }
  await clockState.load();

  final converterState = ConverterState();
  converterState.initializeWithLocal(settingsState.effectiveReferenceTimezone);

  final widgetState = DesktopWidgetState();
  await widgetState.initialize(clockState.cities);

  // Sync widgets whenever clockState cities change
  clockState.addListener(() {
    widgetState.syncWithAvailableCities(clockState.cities);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsState>.value(value: settingsState),
        ChangeNotifierProvider<ClockState>.value(value: clockState),
        ChangeNotifierProvider<ConverterState>.value(value: converterState),
        ChangeNotifierProvider<DesktopWidgetState>.value(value: widgetState),
        ChangeNotifierProvider<MeetingPlannerState>(
          create: (_) => MeetingPlannerState(),
        ),
      ],
      child: const WorldClockApp(),
    ),
  );
}

class WorldClockApp extends StatelessWidget {
  const WorldClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorldClock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DesktopScaffold(),
    );
  }
}
