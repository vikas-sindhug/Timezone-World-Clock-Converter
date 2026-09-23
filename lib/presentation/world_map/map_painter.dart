import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/solar/solar_calculator.dart';
import '../../data/models/world_city.dart';

class WorldMapPainter extends CustomPainter {
  final DateTime utcTime;
  final List<WorldCity> allCities;
  final Set<String> savedCityIds;
  final WorldCity? selectedCity;

  WorldMapPainter({
    required this.utcTime,
    required this.allCities,
    required this.savedCityIds,
    this.selectedCity,
  });

  // Convert (lat, lon) to Canvas (x, y) using Equirectangular Projection
  static Offset latLonToOffset(double lat, double lon, Size size) {
    // lon: -180 to +180 -> x: 0 to width
    // lat: +90 to -90 -> y: 0 to height
    final x = (lon + 180.0) / 360.0 * size.width;
    final y = (90.0 - lat) / 180.0 * size.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ocean Background
    final oceanPaint = Paint()
      ..color = const Color(0xFF0C0F15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, oceanPaint);

    // 2. Subtle Timezone Meridians (every 15 degrees = 1 hour)
    final meridianPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;

    for (int lon = -180; lon <= 180; lon += 15) {
      final x = (lon + 180.0) / 360.0 * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), meridianPaint);
    }

    // Equator and Prime Meridian highlights
    final primePaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;
    final primeX = (0.0 + 180.0) / 360.0 * size.width;
    canvas.drawLine(Offset(primeX, 0), Offset(primeX, size.height), primePaint);

    final equatorY = size.height / 2;
    canvas.drawLine(Offset(0, equatorY), Offset(size.width, equatorY), primePaint);

    // 3. Continental Landmass Vectors
    final landPaint = Paint()
      ..color = const Color(0xFF19202D)
      ..style = PaintingStyle.fill;

    final landBorderPaint = Paint()
      ..color = const Color(0xFF2B3447)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawContinents(canvas, size, landPaint, landBorderPaint);

    // 4. Dynamic Day / Night Solar Terminator
    _drawTerminator(canvas, size);

    // 5. City Markers
    _drawCities(canvas, size);
  }

  void _drawContinents(Canvas canvas, Size size, Paint fill, Paint stroke) {
    for (final polygon in _continentPolygons) {
      final path = Path();
      bool first = true;
      for (final pt in polygon) {
        final offset = latLonToOffset(pt[0], pt[1], size);
        if (first) {
          path.moveTo(offset.dx, offset.dy);
          first = false;
        } else {
          path.lineTo(offset.dx, offset.dy);
        }
      }
      path.close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
  }

  void _drawTerminator(Canvas canvas, Size size) {
    // Generate solar terminator curve points
    final path = Path();
    const step = 2.0; // degree resolution

    // Determine whether the North or South Pole is currently in night
    final northInNight = !SolarCalculator.isDayAt(
      latitude: 89.0,
      longitude: 0.0,
      utcTime: utcTime,
    );

    // Start at top-left or bottom-left depending on which pole is night
    final startLon = -180.0;
    final startLat = SolarCalculator.getTerminatorLatitude(
      longitude: startLon,
      utcTime: utcTime,
    );
    final firstPoint = latLonToOffset(startLat, startLon, size);
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (double lon = -180.0 + step; lon <= 180.0; lon += step) {
      final lat = SolarCalculator.getTerminatorLatitude(
        longitude: lon,
        utcTime: utcTime,
      );
      final pt = latLonToOffset(lat, lon, size);
      path.lineTo(pt.dx, pt.dy);
    }

    // Close the night polygon around the dark pole
    if (northInNight) {
      // Connect to top right, then top left
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else {
      // Connect to bottom right, then bottom left
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    path.close();

    // Night shadow
    final nightPaint = Paint()
      ..color = const Color(0x7306080E) // 45% black night overlay
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, nightPaint);

    // Subtle golden twilight rim along terminator curve
    final twilightRim = Paint()
      ..color = AppColors.dayAmber.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final linePath = Path();
    bool first = true;
    for (double lon = -180.0; lon <= 180.0; lon += step) {
      final lat = SolarCalculator.getTerminatorLatitude(
        longitude: lon,
        utcTime: utcTime,
      );
      final pt = latLonToOffset(lat, lon, size);
      if (first) {
        linePath.moveTo(pt.dx, pt.dy);
        first = false;
      } else {
        linePath.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(linePath, twilightRim);
  }

  void _drawCities(Canvas canvas, Size size) {
    for (final city in allCities) {
      final offset = latLonToOffset(city.latitude, city.longitude, size);
      final isSaved = savedCityIds.contains(city.id);
      final isSelected = selectedCity?.id == city.id;

      if (isSelected) {
        // Glowing target ring
        final glow = Paint()
          ..color = AppColors.accent.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, 10, glow);

        final selPaint = Paint()
          ..color = AppColors.accentLight
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, 4.5, selPaint);
      } else if (isSaved) {
        // Saved city marker
        final outer = Paint()
          ..color = AppColors.accent.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, 6.5, outer);

        final inner = Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, 3.5, inner);
      } else {
        // Regular city dot
        final regular = Paint()
          ..color = AppColors.textMuted.withValues(alpha: 0.6)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, 2.2, regular);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) {
    return oldDelegate.utcTime.second != utcTime.second ||
        oldDelegate.savedCityIds.length != savedCityIds.length ||
        oldDelegate.selectedCity?.id != selectedCity?.id;
  }

  // Simplified continental polygon vertices [lat, lon]
  static final List<List<List<double>>> _continentPolygons = [
    // North America
    [
      [71, -156], [70, -135], [68, -100], [58, -94], [52, -80], [58, -63],
      [47, -53], [44, -64], [30, -81], [25, -80], [29, -89], [26, -97],
      [19, -96], [16, -93], [14, -87], [9, -79], [8, -82], [16, -98],
      [22, -105], [32, -117], [38, -123], [48, -125], [58, -137], [60, -149],
      [59, -152], [64, -166], [71, -156]
    ],
    // South America
    [
      [12, -72], [10, -62], [6, -55], [0, -50], [-4, -36], [-10, -36],
      [-23, -42], [-33, -52], [-38, -57], [-52, -68], [-55, -67], [-53, -74],
      [-42, -73], [-32, -71], [-18, -71], [-5, -80], [4, -77], [10, -75], [12, -72]
    ],
    // Europe
    [
      [71, 28], [69, 33], [65, 41], [55, 38], [47, 30], [42, 28], [37, 24],
      [36, -5], [43, -9], [48, -4], [54, 8], [58, 12], [63, 20], [70, 24], [71, 28]
    ],
    // British Isles
    [
      [58, -3], [54, 0], [50, 1], [50, -5], [54, -4], [58, -5], [58, -3]
    ],
    // Africa
    [
      [37, 10], [32, 25], [31, 32], [28, 34], [22, 37], [12, 44], [11, 51],
      [2, 45], [-11, 40], [-26, 33], [-34, 18], [-34, 26], [-28, 15],
      [-16, 12], [-5, 12], [4, 7], [5, -1], [4, -7], [14, -17], [21, -17],
      [28, -13], [35, -6], [36, 1], [37, 10]
    ],
    // Asia
    [
      [73, 73], [77, 105], [74, 137], [67, 179], [64, -172], [60, 163],
      [53, 142], [44, 132], [38, 128], [30, 122], [22, 114], [13, 109],
      [1, 104], [10, 99], [22, 91], [22, 88], [13, 80], [8, 77], [21, 72],
      [25, 62], [25, 57], [30, 48], [31, 35], [37, 36], [41, 44], [47, 52],
      [55, 60], [60, 60], [68, 68], [73, 73]
    ],
    // India sub-region
    [
      [25, 68], [31, 75], [28, 85], [22, 88], [17, 83], [13, 80],
      [8, 77], [15, 73], [20, 73], [25, 68]
    ],
    // Australia
    [
      [-11, 142], [-14, 144], [-24, 153], [-32, 152], [-38, 147], [-38, 140],
      [-32, 132], [-35, 116], [-28, 114], [-22, 114], [-17, 122], [-14, 126],
      [-12, 132], [-14, 136], [-11, 142]
    ],
    // Japan
    [
      [45, 142], [41, 140], [35, 136], [33, 130], [34, 135], [37, 141], [45, 145], [45, 142]
    ],
    // Greenland
    [
      [83, -30], [81, -12], [76, -18], [65, -39], [60, -44], [64, -52], [72, -55], [78, -69], [83, -30]
    ],
  ];
}
