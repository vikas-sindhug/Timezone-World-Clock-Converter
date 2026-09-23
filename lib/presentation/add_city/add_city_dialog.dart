import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/time/timezone_engine.dart';
import '../../data/models/world_city.dart';
import '../../data/repositories/city_database.dart';
import '../../state/clock_state.dart';
import '../common/glass_button.dart';
import '../common/glass_container.dart';

class AddCityDialog extends StatefulWidget {
  const AddCityDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => const AddCityDialog(),
    );
  }

  @override
  State<AddCityDialog> createState() => _AddCityDialogState();
}

class _AddCityDialogState extends State<AddCityDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<WorldCity> _results = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _results = CityDatabase.popularCities;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text;
      _results = CityDatabase.search(_query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clockState = context.watch<ClockState>();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 640,
          maxHeight: 680,
        ),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(20),
          borderColor: AppColors.glassBorderHighlight,
          borderWidth: 1.2,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: AppColors.accent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            autofocus: true,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search city, country, or timezone (e.g. Tokyo, EST, India)...',
                              hintStyle: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      color: AppColors.textMuted,
                                      onPressed: () => _searchController.clear(),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'ESC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quick Popular Suggestions Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text(
                            'Popular:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          for (final cityName in [
                            'Tokyo',
                            'London',
                            'New York',
                            'Paris',
                            'Jaipur',
                            'Dubai',
                            'Singapore',
                            'Sydney',
                            'Berlin',
                          ]) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () {
                                  _searchController.text = cityName;
                                  _searchController.selection = TextSelection.fromPosition(
                                    TextPosition(offset: cityName.length),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.glassSurface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.glassBorder),
                                  ),
                                  child: Text(
                                    cityName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.glassBorder),

              // Results Count Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  _query.isEmpty
                      ? 'SUGGESTED INTERNATIONAL HUBS (${_results.length})'
                      : 'MATCHING TIMEZONES (${_results.length})',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.accentLight,
                  ),
                ),
              ),

              // City Results List
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_off_outlined,
                              size: 40,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No cities found for "$_query"',
                              style: AppTypography.body,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try searching for another city, country, or timezone identifier.',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 60,
                          color: AppColors.borderSubtle,
                        ),
                        itemBuilder: (context, index) {
                          final city = _results[index];
                          final isAlreadyAdded = clockState.isCitySaved(city.id);
                          final offset = TimezoneEngine.getUtcOffsetString(city.timezoneId);
                          final abbr = TimezoneEngine.getTimezoneAbbreviation(city.timezoneId);
                          final localNow = TimezoneEngine.nowIn(city.timezoneId);
                          final timeStr = '${localNow.hour.toString().padLeft(2, '0')}:${localNow.minute.toString().padLeft(2, '0')}';

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              hoverColor: AppColors.glassSurfaceHover,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.glassSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  city.flagEmoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    city.name,
                                    style: AppTypography.bodyBold.copyWith(
                                      color: isAlreadyAdded
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${city.country} • $timeStr',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${city.timezoneId} • $abbr ($offset)',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              trailing: isAlreadyAdded
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.glassSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.workingHoursGreen.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: AppColors.workingHoursGreen,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Added',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.workingHoursGreen,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : GlassButton(
                                      isPrimary: true,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      borderRadius: BorderRadius.circular(8),
                                      icon: const Icon(Icons.add_rounded, size: 15, color: Colors.white),
                                      label: const Text(
                                        'Add',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                      onPressed: () {
                                        clockState.addCity(city);
                                        HapticFeedback.lightImpact();
                                      },
                                    ),
                            ),
                          );
                        },
                      ),
              ),

              const Divider(height: 1, color: AppColors.glassBorder),

              // Bottom Dismiss Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Press ESC or click outside to dismiss',
                      style: AppTypography.caption,
                    ),
                    GlassButton(
                      isPrimary: false,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      borderRadius: BorderRadius.circular(8),
                      label: const Text('Close', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
