import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kBg        = Color(0xFF0F1117);
const kSurface   = Color(0xFF1A1D27);
const kCard      = Color(0xFF20232F);
const kBorder    = Color(0xFF2D3148);
const kPurple    = Color(0xFF6366F1);
const kGreen     = Color(0xFF22C55E);
const kRed       = Color(0xFFEF4444);
const kOrange    = Color(0xFFF97316);
const kMuted     = Color(0xFF64748B);
const kText      = Color(0xFFE2E8F0);
const kTextDim   = Color(0xFF94A3B8);

ThemeData appTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: kPurple,
      secondary: kGreen,
      surface: kSurface,
      error: kRed,
      onPrimary: Colors.white,
      onSurface: kText,
    ),
    scaffoldBackgroundColor: kBg,
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: kText,
      displayColor: kText,
    ),
    cardTheme: CardTheme(
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPurple, width: 2),
      ),
      labelStyle: const TextStyle(color: kMuted),
      hintStyle: const TextStyle(color: kMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kSurface,
      indicatorColor: kPurple.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, color: kText),
      ),
    ),
    dividerTheme: const DividerThemeData(color: kBorder, thickness: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

// Ícones MDI → IconData Flutter
const Map<String, IconData> kIconMap = {
  'home': Icons.home_outlined,
  'restaurant': Icons.restaurant_outlined,
  'directions_car': Icons.directions_car_outlined,
  'favorite': Icons.favorite_outline,
  'school': Icons.school_outlined,
  'celebration': Icons.celebration_outlined,
  'receipt_long': Icons.receipt_long_outlined,
  'work': Icons.work_outline,
  'computer': Icons.computer_outlined,
  'add_circle': Icons.add_circle_outline,
  'more_horiz': Icons.more_horiz,
  'checkroom': Icons.checkroom_outlined,
  'attach_money': Icons.attach_money,
  'trending_up': Icons.trending_up,
  'fitness_center': Icons.fitness_center_outlined,
  'music_note': Icons.music_note_outlined,
  'local_cafe': Icons.local_cafe_outlined,
  'sports_bar': Icons.sports_bar_outlined,
  'local_pharmacy': Icons.local_pharmacy_outlined,
  'child_care': Icons.child_care_outlined,
  'flight': Icons.flight_outlined,
  'smartphone': Icons.smartphone_outlined,
  'pets': Icons.pets_outlined,
  'local_gas_station': Icons.local_gas_station_outlined,
  'local_hospital': Icons.local_hospital_outlined,
  'lightbulb': Icons.lightbulb_outline,
  'card_giftcard': Icons.card_giftcard_outlined,
  'fastfood': Icons.fastfood_outlined,
  'key': Icons.key_outlined,
  'sports_esports': Icons.sports_esports_outlined,
};

IconData iconData(String name) => kIconMap[name] ?? Icons.more_horiz;

// Cor hex → Color
Color hexColor(String hex) {
  try {
    return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
  } catch (_) {
    return kPurple;
  }
}


ThemeData appThemeLight() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme.light(
      primary: kPurple,
      secondary: kGreen,
      surface: Colors.white,
      background: const Color(0xFFF8FAFC),
      error: kRed,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kPurple.withOpacity(0.15),
    ),
  );
}
