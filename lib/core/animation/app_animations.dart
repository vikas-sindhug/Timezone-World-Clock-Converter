import 'package:flutter/material.dart';

/// Centralized animation constants and curves for the Liquid Glass motion system.
class AppAnimations {
  // Standard Durations
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration medium = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 550);
  static const Duration staggeredStep = Duration(milliseconds: 45);

  // Apple / Fluid Curves
  static const Curve smooth = Curves.easeOutCubic;
  static const Curve smoothInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve fluid = Curves.fastOutSlowIn;
  static const Curve bounce = Curves.elasticOut;

  /// Returns effective duration taking into account reduced motion settings.
  static Duration getDuration(Duration duration, {bool reducedMotion = false}) {
    if (reducedMotion) {
      return Duration(milliseconds: (duration.inMilliseconds * 0.25).clamp(0, 80).toInt());
    }
    return duration;
  }

  /// Returns effective curve taking into account reduced motion settings.
  static Curve getCurve(Curve curve, {bool reducedMotion = false}) {
    if (reducedMotion) {
      return Curves.linear;
    }
    return curve;
  }
}
