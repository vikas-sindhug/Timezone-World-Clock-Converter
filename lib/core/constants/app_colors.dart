import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0C10);
  static const Color backgroundSecondary = Color(0xFF0F1218);
  
  // Surfaces
  static const Color surface = Color(0xFF141822);
  static const Color surfaceElevated = Color(0xFF1B202D);
  static const Color surfaceHover = Color(0xFF222938);
  static const Color surfaceActive = Color(0xFF2B3347);
  
  // Borders
  static const Color border = Color(0xFF232B3B);
  static const Color borderSubtle = Color(0xFF19202D);
  static const Color borderFocus = Color(0xFF3B82F6);
  
  // Accents
  static const Color accent = Color(0xFF3B82F6); // Blue
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accentMuted = Color(0x263B82F6); // 15% opacity
  
  // Semantic status
  static const Color dayAmber = Color(0xFFF59E0B);
  static const Color dayAmberMuted = Color(0x26F59E0B);
  static const Color nightIndigo = Color(0xFF818CF8);
  static const Color nightIndigoMuted = Color(0x26818CF8);
  static const Color workingHoursGreen = Color(0xFF10B981);
  static const Color workingHoursGreenMuted = Color(0x2610B981);
  static const Color redDanger = Color(0xFFEF4444);
  static const Color redDangerMuted = Color(0x26EF4444);
  
  // Typography
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);
  
  // Liquid Glass Design Tokens
  static const Color glassBaseDark = Color(0xFF07090E);
  static const Color glassSurface = Color(0x99141926); // Translucent dark charcoal navy (60%)
  static const Color glassSurfaceHigh = Color(0xCC0F1420); // 80% opacity for deep contrast
  static const Color glassSurfaceLow = Color(0x55192235); // 33% opacity for subtle layers
  static const Color glassSurfaceHover = Color(0xB21A2234); // 70% opacity
  static const Color glassSurfaceActive = Color(0xCC202A40);

  // Glass Specular Borders (Light refraction)
  static const Color glassBorder = Color(0x1FFFFFFF); // 12% white specular rim
  static const Color glassBorderHighlight = Color(0x38FFFFFF); // 22% white top reflection
  static const Color glassBorderAccent = Color(0x593B82F6); // 35% accent blue glass border

  // Glass Blue Accents
  static const Color glassAccent = Color(0x4D3B82F6); // 30% blue glass
  static const Color glassAccentHover = Color(0x663B82F6); // 40% blue glass

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x4D000000),
      offset: Offset(0, 6),
      blurRadius: 18,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> glassShadowHover = [
    BoxShadow(
      color: Color(0x66000000),
      offset: Offset(0, 10),
      blurRadius: 26,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x2E3B82F6),
      offset: Offset(0, 0),
      blurRadius: 20,
      spreadRadius: 1,
    ),
  ];

  static const List<BoxShadow> glowBlue = [
    BoxShadow(
      color: Color(0x263B82F6),
      offset: Offset(0, 0),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];
}
