import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/animation/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/time/timezone_engine.dart';
import '../../data/repositories/city_database.dart';
import '../../state/clock_state.dart';
import '../../state/settings_state.dart';
import '../add_city/add_city_dialog.dart';
import '../common/glass_button.dart';
import '../common/glass_container.dart';
import '../common/glass_scaffold_background.dart';
import '../converter/time_converter_view.dart';
import '../converter/time_difference_view.dart';
import '../dashboard/dashboard_view.dart';
import '../meeting_planner/meeting_planner_view.dart';
import '../timeline/world_timeline_view.dart';
import '../widgets/widget_configure_sheet.dart';
import '../widgets/widgets_view.dart';
import '../world_map/world_map_view.dart';
import '../../services/deep_link_service.dart';

class DesktopScaffold extends StatefulWidget {
  const DesktopScaffold({super.key});

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _views = const [
    DashboardView(),
    WorldMapView(),
    TimeConverterView(),
    TimeDifferenceView(),
    MeetingPlannerView(),
    WorldTimelineView(),
    WidgetsView(),
  ];

  @override
  void initState() {
    super.initState();
    DeepLinkService().deepLinkedCityId.addListener(_handleDeepLink);
  }

  @override
  void dispose() {
    DeepLinkService().deepLinkedCityId.removeListener(_handleDeepLink);
    super.dispose();
  }

  void _handleDeepLink() {
    final cityId = DeepLinkService().deepLinkedCityId.value;
    if (cityId != null) {
      setState(() => _selectedIndex = 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opened clock from Desktop Widget ($cityId)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      DeepLinkService().clearDeepLink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clockState = context.watch<ClockState>();
    final settingsState = context.watch<SettingsState>();
    final refTz = clockState.effectiveReferenceTimezone;

    // Keyboard Shortcuts (Ctrl+K / Cmd+K to open search)
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          AddCityDialog.show(context);
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          AddCityDialog.show(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: GlassScaffoldBackground(
            child: Row(
              children: [
                // Sidebar Navigation with Liquid Glass Styling
                Container(
                  width: 236,
                  decoration: BoxDecoration(
                    color: settingsState.glassEffectsEnabled
                        ? AppColors.glassSurfaceLow
                        : AppColors.surface,
                    border: const Border(
                      right: BorderSide(color: AppColors.glassBorder, width: 1),
                    ),
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Branding Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.schedule_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WorldClock',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Desktop Utility',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick Search Shortcut Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: InkWell(
                        onTap: () => AddCityDialog.show(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Quick Search...',
                                  style: AppTypography.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: const Text(
                                  '⌘K',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: 12),

                    // Navigation Items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          _NavItem(
                            icon: Icons.access_time_rounded,
                            label: 'World Clocks',
                            badgeCount: clockState.cities.length,
                            isSelected: _selectedIndex == 0,
                            onTap: () => setState(() => _selectedIndex = 0),
                          ),
                          _NavItem(
                            icon: Icons.public_rounded,
                            label: 'World Map',
                            isSelected: _selectedIndex == 1,
                            onTap: () => setState(() => _selectedIndex = 1),
                          ),
                          _NavItem(
                            icon: Icons.swap_horiz_rounded,
                            label: 'Time Converter',
                            isSelected: _selectedIndex == 2,
                            onTap: () => setState(() => _selectedIndex = 2),
                          ),
                          _NavItem(
                            icon: Icons.compare_arrows_rounded,
                            label: 'Time Difference',
                            isSelected: _selectedIndex == 3,
                            onTap: () => setState(() => _selectedIndex = 3),
                          ),
                          _NavItem(
                            icon: Icons.groups_rounded,
                            label: 'Meeting Planner',
                            isSelected: _selectedIndex == 4,
                            onTap: () => setState(() => _selectedIndex = 4),
                          ),
                          _NavItem(
                            icon: Icons.view_timeline_rounded,
                            label: 'World Timeline',
                            isSelected: _selectedIndex == 5,
                            onTap: () => setState(() => _selectedIndex = 5),
                          ),
                          _NavItem(
                            icon: Icons.widgets_rounded,
                            label: 'Desktop Widgets',
                            isSelected: _selectedIndex == 6,
                            onTap: () => setState(() => _selectedIndex = 6),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: AppColors.borderSubtle),

                    // Bottom Reference Timezone & Settings Bar
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(12),
                        borderRadius: BorderRadius.circular(12),
                        borderColor: AppColors.glassBorder,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.accentLight),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    refTz,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Offset: ${TimezoneEngine.getUtcOffsetString(refTz)}',
                              style: AppTypography.caption,
                            ),
                            const SizedBox(height: 10),
                            GlassButton(
                              isPrimary: false,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              borderRadius: BorderRadius.circular(8),
                              onPressed: () => _showSettingsDialog(context, settingsState, clockState),
                              icon: const Icon(Icons.tune_rounded, size: 13, color: AppColors.textSecondary),
                              label: const Text(
                                'Preferences',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main View Area with Smooth Fluid Transitions
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppAnimations.getDuration(
                    AppAnimations.fast,
                    reducedMotion: settingsState.reducedMotion,
                  ),
                  switchInCurve: AppAnimations.getCurve(
                    AppAnimations.smooth,
                    reducedMotion: settingsState.reducedMotion,
                  ),
                  switchOutCurve: AppAnimations.getCurve(
                    AppAnimations.smooth,
                    reducedMotion: settingsState.reducedMotion,
                  ),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_selectedIndex),
                    child: _views[_selectedIndex],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showSettingsDialog(
    BuildContext context,
    SettingsState settingsState,
    ClockState clockState,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(20),
              borderColor: AppColors.glassBorderHighlight,
              borderWidth: 1.2,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppColors.accentLight, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('Settings & Preferences', style: AppTypography.h2),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section: Appearance & Liquid Glass
                    const Text(
                      'APPEARANCE & MOTION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.accentLight,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Liquid Glass Visuals', style: AppTypography.bodyBold),
                      subtitle: const Text('Translucent surfaces and specular borders', style: AppTypography.caption),
                      value: settingsState.glassEffectsEnabled,
                      activeTrackColor: AppColors.accent,
                      activeThumbColor: Colors.white,
                      onChanged: (_) => settingsState.toggleGlassEffects(),
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reduced Motion', style: AppTypography.bodyBold),
                      subtitle: const Text('Minimize UI animations for accessibility', style: AppTypography.caption),
                      value: settingsState.reducedMotion,
                      activeTrackColor: AppColors.accent,
                      activeThumbColor: Colors.white,
                      onChanged: (_) => settingsState.toggleReducedMotion(),
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Glass Transparency', style: AppTypography.bodyBold),
                      subtitle: const Text('Adjust backdrop translucency density', style: AppTypography.caption),
                      trailing: DropdownButton<String>(
                        value: settingsState.transparencyLevel,
                        dropdownColor: AppColors.surfaceElevated,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 'high', child: Text('High', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'medium', child: Text('Medium', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'low', child: Text('Low', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) {
                          if (val != null) settingsState.setTransparencyLevel(val);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: 14),

                    // Section: Clocks & Time Display
                    const Text(
                      'TIME DISPLAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.accentLight,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('24-Hour Time Format', style: AppTypography.bodyBold),
                      subtitle: const Text('Display hours as 00:00 to 23:59', style: AppTypography.caption),
                      value: settingsState.is24Hour,
                      activeTrackColor: AppColors.accent,
                      activeThumbColor: Colors.white,
                      onChanged: (_) => settingsState.toggle24Hour(),
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Display Seconds', style: AppTypography.bodyBold),
                      subtitle: const Text('Show live ticking seconds on clocks', style: AppTypography.caption),
                      value: settingsState.showSeconds,
                      activeTrackColor: AppColors.accent,
                      activeThumbColor: Colors.white,
                      onChanged: (_) => settingsState.toggleShowSeconds(),
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Analog Clock Dial', style: AppTypography.bodyBold),
                      subtitle: const Text('Show minimalist analog face on cards', style: AppTypography.caption),
                      value: settingsState.showAnalogClock,
                      activeTrackColor: AppColors.accent,
                      activeThumbColor: Colors.white,
                      onChanged: (_) => settingsState.toggleShowAnalogClock(),
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: 14),

                    const Text('Reference Timezone', style: AppTypography.bodyBold),
                    const SizedBox(height: 4),
                    Text(
                      'Local system detected: ${TimezoneEngine.localTimezoneId}',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String?>(
                      initialValue: settingsState.referenceTimezone,
                      dropdownColor: AppColors.surfaceElevated,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('System Local Timezone (Auto)'),
                        ),
                        ...CityDatabase.allCities.map((c) {
                          return DropdownMenuItem<String?>(
                            value: c.timezoneId,
                            child: Text('${c.name} (${c.timezoneId})'),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        settingsState.setReferenceTimezone(val);
                        clockState.setReferenceTimezone(val);
                      },
                    ),

                    const SizedBox(height: 20),
                    const Text('macOS Desktop Widgets', style: AppTypography.bodyBold),
                    const SizedBox(height: 4),
                    const Text(
                      'Configure live WidgetKit clocks, display formats, and active slots',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 10),
                    GlassButton(
                      icon: const Icon(Icons.widgets_rounded, size: 16),
                      label: const Text('Open Widget Configuration'),
                      isPrimary: false,
                      onPressed: () {
                        Navigator.of(context).pop();
                        WidgetConfigureSheet.show(context);
                      },
                    ),

                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GlassButton(
                        isPrimary: true,
                        onPressed: () => Navigator.of(context).pop(),
                        label: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int? badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.badgeCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final isGlass = settings.glassEffectsEnabled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: AppAnimations.getDuration(
            AppAnimations.fast,
            reducedMotion: settings.reducedMotion,
          ),
          curve: AppAnimations.getCurve(
            AppAnimations.smooth,
            reducedMotion: settings.reducedMotion,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (isGlass ? AppColors.glassAccent.withValues(alpha: 0.16) : AppColors.surfaceHover)
                : (_isHovered ? AppColors.glassSurfaceHover : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.glassBorderAccent
                  : (_isHovered ? AppColors.glassBorder : Colors.transparent),
              width: 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              splashColor: AppColors.accent.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      size: 18,
                      color: widget.isSelected ? AppColors.accentLight : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (widget.badgeCount != null) ...[
                      AnimatedContainer(
                        duration: AppAnimations.getDuration(
                          AppAnimations.fast,
                          reducedMotion: settings.reducedMotion,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.isSelected ? AppColors.accent : AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.isSelected ? Colors.transparent : AppColors.glassBorder,
                          ),
                        ),
                        child: Text(
                          widget.badgeCount.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: widget.isSelected ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
