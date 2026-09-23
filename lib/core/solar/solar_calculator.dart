import 'dart:math' as math;

class SolarTimes {
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? solarNoon;
  final bool isPolarDay;
  final bool isPolarNight;

  const SolarTimes({
    this.sunrise,
    this.sunset,
    this.solarNoon,
    this.isPolarDay = false,
    this.isPolarNight = false,
  });
}

class SolarPosition {
  final double altitudeDegrees; // -90 to +90
  final double azimuthDegrees; // 0 to 360
  final bool isDay;
  final String phase; // Day, Golden Hour, Twilight, Night
  final double? dayProgress; // 0.0 to 1.0 during day, or null

  const SolarPosition({
    required this.altitudeDegrees,
    required this.azimuthDegrees,
    required this.isDay,
    required this.phase,
    this.dayProgress,
  });
}

class SolarCalculator {
  static const double _rad = math.pi / 180.0;
  static const double _deg = 180.0 / math.pi;

  /// Calculate sunrise, sunset and solar noon for a given coordinate and date (UTC).
  static SolarTimes calculateSolarTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    final jd = _julianDay(utcDate);

    // Number of days since J2000.0
    final n = jd - 2451545.0 + 0.0008;

    // Mean solar noon
    final jStar = n - (longitude / 360.0);

    // Solar mean anomaly
    final m = (357.5291 + 0.98560028 * jStar) % 360.0;
    final mRad = m * _rad;

    // Equation of the center
    final c = 1.9148 * math.sin(mRad) +
        0.0200 * math.sin(2 * mRad) +
        0.0003 * math.sin(3 * mRad);

    // Ecliptic longitude
    final lambda = (m + c + 180.0 + 102.9372) % 360.0;
    final lambdaRad = lambda * _rad;

    // Solar transit (solar noon in Julian date)
    final jTransit = 2451545.0 +
        jStar +
        0.0053 * math.sin(mRad) -
        0.0069 * math.sin(2 * lambdaRad);

    // Declination of the Sun
    final sinDelta = math.sin(lambdaRad) * math.sin(23.44 * _rad);
    final cosDelta = math.sqrt(1 - sinDelta * sinDelta);

    final latRad = latitude * _rad;

    // Hour angle for standard sunrise/sunset (solar zenith = 90.833 deg)
    // cos(omega0) = (sin(-0.833) - sin(lat)*sin(delta)) / (cos(lat)*cos(delta))
    final cosOmega0 = (math.sin(-0.833 * _rad) - math.sin(latRad) * sinDelta) /
        (math.cos(latRad) * cosDelta);

    if (cosOmega0 > 1.0) {
      // Polar night (Sun never rises)
      return SolarTimes(
        solarNoon: _fromJulianDate(jTransit),
        isPolarNight: true,
      );
    } else if (cosOmega0 < -1.0) {
      // Polar day (Sun never sets)
      return SolarTimes(
        solarNoon: _fromJulianDate(jTransit),
        isPolarDay: true,
      );
    }

    final omega0 = math.acos(cosOmega0) * _deg;
    final jSet = jTransit + (omega0 / 360.0);
    final jRise = jTransit - (omega0 / 360.0);

    return SolarTimes(
      sunrise: _fromJulianDate(jRise),
      sunset: _fromJulianDate(jSet),
      solarNoon: _fromJulianDate(jTransit),
    );
  }

  /// Calculate current solar position (altitude and azimuth) for a location at a given UTC time.
  static SolarPosition calculatePosition({
    required double latitude,
    required double longitude,
    required DateTime utcTime,
  }) {
    final jd = _julianDay(utcTime) -
        0.5 +
        (utcTime.hour + utcTime.minute / 60.0 + utcTime.second / 3600.0) / 24.0;
    final d = jd - 2451545.0;

    // Keplerian elements
    final q = (280.459 + 0.98564736 * d) % 360.0;
    final g = (357.529 + 0.98560028 * d) % 360.0;
    final gRad = g * _rad;

    final l = (q + 1.915 * math.sin(gRad) + 0.020 * math.sin(2 * gRad)) % 360.0;
    final lRad = l * _rad;

    final e = (23.439 - 0.00000036 * d) * _rad;

    // Declination and Right Ascension
    final sinDelta = math.sin(e) * math.sin(lRad);
    final cosDelta = math.cos(math.asin(sinDelta));

    final y = math.cos(e) * math.sin(lRad);
    final x = math.cos(lRad);
    var ra = math.atan2(y, x) * _deg;
    if (ra < 0) ra += 360.0;

    // Greenwich Mean Sidereal Time (GMST)
    final gmst = (280.46061837 +
            360.98564736629 * (jd - 2451545.0) +
            0.000387933 * math.pow((jd - 2451545.0) / 36525.0, 2)) %
        360.0;

    // Local Sidereal Time
    final lmst = (gmst + longitude) % 360.0;

    // Hour angle
    var ha = (lmst - ra) % 360.0;
    if (ha < 0) ha += 360.0;
    final haRad = ha * _rad;
    final latRad = latitude * _rad;

    // Altitude (elevation)
    final sinAlt = math.sin(latRad) * sinDelta +
        math.cos(latRad) * cosDelta * math.cos(haRad);
    final altRad = math.asin(sinAlt.clamp(-1.0, 1.0));
    final altDeg = altRad * _deg;

    // Azimuth
    final cosAz = (sinDelta - math.sin(latRad) * sinAlt) /
        (math.cos(latRad) * math.cos(altRad));
    var azDeg = math.acos(cosAz.clamp(-1.0, 1.0)) * _deg;
    if (math.sin(haRad) > 0) {
      azDeg = 360.0 - azDeg;
    }

    final isDay = altDeg >= -0.833;

    String phase;
    if (altDeg > 6.0) {
      phase = 'Day';
    } else if (altDeg >= -0.833) {
      phase = 'Golden Hour';
    } else if (altDeg >= -6.0) {
      phase = 'Civil Twilight';
    } else if (altDeg >= -12.0) {
      phase = 'Nautical Twilight';
    } else if (altDeg >= -18.0) {
      phase = 'Astronomical Twilight';
    } else {
      phase = 'Night';
    }

    return SolarPosition(
      altitudeDegrees: altDeg,
      azimuthDegrees: azDeg,
      isDay: isDay,
      phase: phase,
    );
  }

  /// Calculates the latitude on the day/night terminator curve for a given longitude at utcTime.
  /// Used for dynamic world map day/night shading.
  /// Returns terminator latitude in degrees (-90 to +90).
  static double getTerminatorLatitude({
    required double longitude,
    required DateTime utcTime,
  }) {
    // Calculate Sun's declination and Greenwich hour angle (subsolar point)
    final jd = _julianDay(utcTime) -
        0.5 +
        (utcTime.hour + utcTime.minute / 60.0 + utcTime.second / 3600.0) / 24.0;
    final d = jd - 2451545.0;

    final g = (357.529 + 0.98560028 * d) % 360.0;
    final gRad = g * _rad;
    final l = (280.459 + 0.98564736 * d + 1.915 * math.sin(gRad)) % 360.0;
    final lRad = l * _rad;
    final e = 23.439 * _rad;

    // Declination
    final delta = math.asin(math.sin(e) * math.sin(lRad));

    // Greenwich Hour Angle of the sun (subsolar longitude is -gha)
    // Approximate subsolar point longitude:
    // Subsolar point moves 360 degrees in 24h, at 12:00 UTC it is roughly at lon 0
    final subsolarLon = (12.0 - (utcTime.hour + utcTime.minute / 60.0 + utcTime.second / 3600.0)) * 15.0;

    final deltaLon = (longitude - subsolarLon) * _rad;

    // On terminator, solar zenith = 90 deg -> cos(zenith) = 0
    // sin(lat)*sin(delta) + cos(lat)*cos(delta)*cos(deltaLon) = 0
    // tan(lat) = -cos(deltaLon) / tan(delta)
    if (delta.abs() < 0.001) {
      return 0.0;
    }

    final tanLat = -math.cos(deltaLon) / math.tan(delta);
    final lat = math.atan(tanLat) * _deg;
    return lat.clamp(-89.9, 89.9);
  }

  /// Check if a coordinate is in daylight at a given UTC time
  static bool isDayAt({
    required double latitude,
    required double longitude,
    required DateTime utcTime,
  }) {
    final pos = calculatePosition(
      latitude: latitude,
      longitude: longitude,
      utcTime: utcTime,
    );
    return pos.isDay;
  }

  static double _julianDay(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;

    var a = (14 - m) ~/ 12;
    var y0 = y + 4800 - a;
    var m0 = m + 12 * a - 3;

    return d +
        ((153 * m0 + 2) ~/ 5) +
        365 * y0 +
        (y0 ~/ 4) -
        (y0 ~/ 100) +
        (y0 ~/ 400) -
        32045.0;
  }

  static DateTime _fromJulianDate(double jd) {
    final z = (jd + 0.5).floor();
    final f = (jd + 0.5) - z;

    int a = z;
    if (z >= 2299161) {
      final alpha = ((z - 1867216.25) / 36524.25).floor();
      a = z + 1 + alpha - (alpha ~/ 4);
    }

    final b = a + 1524;
    final c = ((b - 122.1) / 365.25).floor();
    final d = (365.25 * c).floor();
    final e = ((b - d) / 30.6001).floor();

    final day = b - d - (30.6001 * e).floor();
    final month = e < 14 ? e - 1 : e - 13;
    final year = month > 2 ? c - 4716 : c - 4715;

    final dayFraction = f;
    final totalSeconds = (dayFraction * 86400).round();
    final hours = (totalSeconds ~/ 3600) % 24;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return DateTime.utc(year, month, day, hours, minutes, seconds);
  }
}
