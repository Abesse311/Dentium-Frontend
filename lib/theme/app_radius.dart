import 'package:flutter/material.dart';

class AppRadius {
  // --- Raw Radius Values ---
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 10.0;
  static const double xl = 12.0;
  static const double xxl = 16.0;
  static const double pill = 20.0;
  static const double full = 999.0;

  // --- Radius Objects ---
  static const Radius radiusXs = Radius.circular(xs);
  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusXl = Radius.circular(xl);
  static const Radius radiusXxl = Radius.circular(xxl);
  static const Radius radiusPill = Radius.circular(pill);
  static const Radius radiusFull = Radius.circular(full);

  // --- BorderRadius Objects ---
  static const BorderRadius borderRadiusXs = BorderRadius.all(radiusXs);
  static const BorderRadius borderRadiusSm = BorderRadius.all(radiusSm);
  static const BorderRadius borderRadiusMd = BorderRadius.all(radiusMd);
  static const BorderRadius borderRadiusLg = BorderRadius.all(radiusLg);
  static const BorderRadius borderRadiusXl = BorderRadius.all(radiusXl);
  static const BorderRadius borderRadiusXxl = BorderRadius.all(radiusXxl);
  static const BorderRadius borderRadiusPill = BorderRadius.all(radiusPill);
  static const BorderRadius borderRadiusFull = BorderRadius.all(radiusFull);
}
