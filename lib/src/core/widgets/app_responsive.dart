import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared layout breakpoints used by pages that must run on compact phones,
/// regular phones and tablets without duplicating viewport math.
class AppResponsive {
  const AppResponsive._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isCompact(BuildContext context) => width(context) < 360;

  static bool isTablet(BuildContext context) => width(context) >= 600;

  static double dialogWidth(
    BuildContext context, {
    double maxWidth = 560,
    double horizontalInset = 28,
  }) {
    return math.min(maxWidth, math.max(0, width(context) - horizontalInset));
  }

  /// Keeps accessibility scaling while preventing localized labels from
  /// making the compact navigation and dense data tables unusable.
  static double textScale(BuildContext context) {
    final requested = MediaQuery.textScalerOf(context).scale(1);
    final maximum = width(context) < 360
        ? 1.05
        : width(context) < 600
        ? 1.15
        : 1.25;
    return requested.clamp(0.9, maximum).toDouble();
  }
}
