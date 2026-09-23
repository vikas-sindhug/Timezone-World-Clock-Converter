import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animation/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/time/time_formatter.dart';
import '../../core/time/timezone_engine.dart';
import '../../state/clock_state.dart';
import '../../state/settings_state.dart';
import '../add_city/add_city_dialog.dart';
import '../common/glass_button.dart';
import '../common/glass_container.dart';
import '../common/glass_segmented_control.dart';
import 'clock_card.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final clockState = context.watch<ClockState>();
    final settingsState = context.watch<SettingsState>();

    final cards = clockState.clockCards;
    final nowUtc = clockState.currentUtcTime;
    final refTz = clockState.effectiveReferenceTimezone;
    final localNow = TimezoneEngine.convertTo(nowUtc, refTz);
    final localAbbr = TimezoneEngine.getTimezoneAbbreviation(refTz, nowUtc);
    final localOffset = TimezoneEngine.getUtcOffsetString(refTz, nowUtc);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Top Bar Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Title & Action Controls Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 650;
                      final titleWidget = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.glassAccent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.glassBorderAccent,
                              ),
                            ),
                            child: const Icon(
                              Icons.schedule_rounded,
                              color: AppColors.accentLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WorldClock',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${cards.length} monitored timezones',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ],
                      );

                      final controlsWidget = Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // iPhone-style Sliding Glass Segmented 12h / 24h Toggle
                          GlassSegmentedControl<bool>(
                            values: const [false, true],
                            labels: const ['12h', '24h'],
                            selectedValue: settingsState.is24Hour,
                            onValueChanged: (val) {
                              if (val != settingsState.is24Hour) {
                                settingsState.toggle24Hour();
                              }
                            },
                          ),

                          // Seconds Toggle Button
                          GlassButton(
                            icon: Icon(
                              settingsState.showSeconds
                                  ? Icons.timer_outlined
                                  : Icons.timer_off_outlined,
                              size: 18,
                              color: settingsState.showSeconds
                                  ? AppColors.accentLight
                                  : AppColors.textMuted,
                            ),
                            tooltip: settingsState.showSeconds
                                ? 'Hide seconds'
                                : 'Show seconds',
                            onPressed: () => settingsState.toggleShowSeconds(),
                          ),

                          // Analog Clock Toggle Button
                          GlassButton(
                            icon: Icon(
                              settingsState.showAnalogClock
                                  ? Icons.watch_later_outlined
                                  : Icons.watch_later,
                              size: 18,
                              color: settingsState.showAnalogClock
                                  ? AppColors.accentLight
                                  : AppColors.textMuted,
                            ),
                            tooltip: settingsState.showAnalogClock
                                ? 'Hide analog dial'
                                : 'Show analog dial',
                            onPressed: () =>
                                settingsState.toggleShowAnalogClock(),
                          ),

                          // Add City Button
                          GlassButton(
                            isPrimary: true,
                            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                            label: const Text(
                              'Add City',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () => AddCityDialog.show(context),
                          ),
                        ],
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleWidget,
                            const SizedBox(height: 12),
                            controlsWidget,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          titleWidget,
                          const Spacer(),
                          controlsWidget,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // Hero Banner: Local System Time Information (Liquid Glass & Fully Responsive)
                  GlassContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    borderRadius: BorderRadius.circular(14),
                    borderColor: AppColors.glassBorderHighlight,
                    child: LayoutBuilder(
                      builder: (context, bannerConstraints) {
                        final isNarrow = bannerConstraints.maxWidth < 620;

                        final leftInfo = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.workingHoursGreenMuted,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.my_location_rounded,
                                size: 16,
                                color: AppColors.workingHoursGreen,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 2,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Text(
                                        'YOUR REFERENCE TIMEZONE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                          color: AppColors.workingHoursGreen,
                                        ),
                                      ),
                                      Text(
                                        '$refTz • $localAbbr ($localOffset)',
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    TimeFormatter.formatFullDate(localNow),
                                    style: AppTypography.bodyBold.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );

                        final rightClock = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              TimeFormatter.formatDigitalTime(
                                localNow,
                                is24Hour: settingsState.is24Hour,
                                showSeconds: settingsState.showSeconds,
                              ),
                              style: AppTypography.clockMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (!settingsState.is24Hour) ...[
                              const SizedBox(width: 6),
                              Text(
                                TimeFormatter.getAmPm(localNow),
                                style: AppTypography.clockAmPm,
                              ),
                            ],
                          ],
                        );

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              leftInfo,
                              const SizedBox(height: 10),
                              rightClock,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: leftInfo),
                            const SizedBox(width: 16),
                            rightClock,
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Clock Cards: Adaptive Multi-Column Responsive Layout
          if (cards.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 56,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No world clocks added yet',
                      style: AppTypography.h2,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your favorite global cities to monitor their local time live.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 20),
                    GlassButton(
                      isPrimary: true,
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text('Add Your First City', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      onPressed: () => AddCityDialog.show(context),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;

                  // Adaptive column count based on available content width
                  final int columnCount;
                  if (availableWidth >= 1600) {
                    columnCount = 4;
                  } else if (availableWidth >= 1100) {
                    columnCount = 3;
                  } else if (availableWidth >= 680) {
                    columnCount = 2;
                  } else {
                    columnCount = 1;
                  }

                  // Build rows of cards using IntrinsicHeight to let cards size naturally
                  final rows = <Widget>[];
                  for (int i = 0; i < cards.length; i += columnCount) {
                    final rowCards =
                        cards.sublist(i, (i + columnCount).clamp(0, cards.length));
                    rows.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int j = 0; j < columnCount; j++) ...[
                                if (j > 0) const SizedBox(width: 18),
                                Expanded(
                                  child: j < rowCards.length
                                      ? TweenAnimationBuilder<double>(
                                          duration: AppAnimations.getDuration(
                                            Duration(milliseconds: 220 + ((i + j) * 35).clamp(0, 300)),
                                            reducedMotion: settingsState.reducedMotion,
                                          ),
                                          curve: AppAnimations.getCurve(
                                            AppAnimations.smooth,
                                            reducedMotion: settingsState.reducedMotion,
                                          ),
                                          tween: Tween<double>(begin: 0.0, end: 1.0),
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset: Offset(0, (1.0 - value) * 10),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: ClockCard(
                                            key: ValueKey(rowCards[j].city.id),
                                            data: rowCards[j],
                                            is24Hour: settingsState.is24Hour,
                                            showSeconds:
                                                settingsState.showSeconds,
                                            showAnalogClock:
                                                settingsState.showAnalogClock,
                                            onToggleFavorite: () => clockState
                                                .toggleFavorite(rowCards[j].city.id),
                                            onRemove: () => clockState
                                                .removeCity(rowCards[j].city.id),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
                    child: Column(
                      children: rows,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
