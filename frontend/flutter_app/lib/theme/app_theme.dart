import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  // Backgrounds
  static const bg        = Color(0xFF050D1A);
  static const surface   = Color(0xFF0A1628);
  static const card      = Color(0xFF0F1F35);
  static const cardHi    = Color(0xFF142540);
  static const divider   = Color(0xFF1B3050);

  // Brand
  static const teal      = Color(0xFF00BFA5);
  static const tealDim   = Color(0xFF008C7A);
  static const tealGlow  = Color(0x1A00BFA5);
  static const tealBorder= Color(0x3300BFA5);
  static const cyan      = Color(0xFF18FFFF);

  // Text
  static const t1        = Color(0xFFE2EEF5);
  static const t2        = Color(0xFF6B8FA8);
  static const t3        = Color(0xFF324F65);

  // Semantics
  static const ok        = Color(0xFF00E5A0);
  static const warn      = Color(0xFFFFB830);
  static const err       = Color(0xFFFF4560);
  static const errGlow   = Color(0x22FF4560);
  static const info      = Color(0xFF448AFF);

  // Tumor class colours
  static const glioma    = Color(0xFFFF4560);   // red
  static const mening    = Color(0xFFFFB830);   // amber
  static const pitu      = Color(0xFF00BFA5);   // teal
  static const noTumor   = Color(0xFF00E5A0);   // green

  static const tealGrad  = LinearGradient(
    colors: [teal, Color(0xFF0097A7)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const bgGrad = LinearGradient(
    colors: [bg, Color(0xFF071220)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const cardGrad = LinearGradient(
    colors: [card, cardHi],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.teal, secondary: C.cyan, surface: C.surface, error: C.err,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: C.t2, displayColor: C.t1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0,
      iconTheme: IconThemeData(color: C.t2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: C.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: C.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: C.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: C.teal, width: 1.5),
      ),
      labelStyle: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 14),
      hintStyle: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 14),
    ),
  );
}
