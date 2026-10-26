import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Cores semânticas (independentes do tema) ──────────────
const kGreen     = Color(0xFF22C55E);
const kRed       = Color(0xFFEF4444);
const kOrange    = Color(0xFFF97316);

// ── Cores do tema ativo (redirecionam para o tema atual) ──
// Usadas diretamente no código — serão substituídas pelo tema selecionado.
// Para compatibilidade, mantemos como constantes do tema padrão (Roxo Escuro).
const kPurple    = Color(0xFF6366F1);
const kBg        = Color(0xFF0F1117);
const kSurface   = Color(0xFF1A1D27);
const kCard      = Color(0xFF20232F);
const kBorder    = Color(0xFF2D3148);
const kMuted     = Color(0xFF64748B);
const kText      = Color(0xFFE2E8F0);
const kTextDim   = Color(0xFF94A3B8);

// ── Configuração de tema ──────────────────────────────────
class AppThemeConfig {
  final String id;
  final String label;
  final Color accent;
  final Color bg;
  final Color surface;
  final Color card;
  final Color border;
  final Color text;
  final Color textDim;
  final Color muted;
  final bool isDark;

  const AppThemeConfig({
    required this.id,
    required this.label,
    required this.accent,
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.text,
    required this.textDim,
    required this.muted,
    required this.isDark,
  });
}

// ── Catálogo de temas ─────────────────────────────────────
const kThemes = <AppThemeConfig>[
  // ── Escuros ──
  AppThemeConfig(
    id: 'dark_purple', label: 'Roxo',
    accent: Color(0xFF6366F1),
    bg: Color(0xFF0F1117), surface: Color(0xFF1A1D27),
    card: Color(0xFF20232F), border: Color(0xFF2D3148),
    text: Color(0xFFE2E8F0), textDim: Color(0xFF94A3B8), muted: Color(0xFF64748B),
    isDark: true,
  ),
  AppThemeConfig(
    id: 'dark_blue', label: 'Azul',
    accent: Color(0xFF3B82F6),
    bg: Color(0xFF0A0F1E), surface: Color(0xFF131929),
    card: Color(0xFF1A2236), border: Color(0xFF263355),
    text: Color(0xFFE2E8F0), textDim: Color(0xFF94A3B8), muted: Color(0xFF64748B),
    isDark: true,
  ),
  AppThemeConfig(
    id: 'dark_green', label: 'Verde',
    accent: Color(0xFF10B981),
    bg: Color(0xFF081510), surface: Color(0xFF0F2017),
    card: Color(0xFF152B1E), border: Color(0xFF1E3F2A),
    text: Color(0xFFE2E8F0), textDim: Color(0xFF94A3B8), muted: Color(0xFF64748B),
    isDark: true,
  ),
  AppThemeConfig(
    id: 'dark_red', label: 'Vermelho',
    accent: Color(0xFFEF4444),
    bg: Color(0xFF150A0A), surface: Color(0xFF211010),
    card: Color(0xFF2A1414), border: Color(0xFF3F1E1E),
    text: Color(0xFFE2E8F0), textDim: Color(0xFF94A3B8), muted: Color(0xFF64748B),
    isDark: true,
  ),
  AppThemeConfig(
    id: 'dark_orange', label: 'Laranja',
    accent: Color(0xFFF97316),
    bg: Color(0xFF130E08), surface: Color(0xFF1E1510),
    card: Color(0xFF271C13), border: Color(0xFF3D2A1A),
    text: Color(0xFFE2E8F0), textDim: Color(0xFF94A3B8), muted: Color(0xFF64748B),
    isDark: true,
  ),
  AppThemeConfig(
    id: 'dark_pink', label: 'Rosa',
    accent: Color(0xFFEC4899),
    bg: Color(0xFF130B12), surface: Color(0xFF1E1020),
    card: Color(0xFF28152A), border: Color(0xFF3D1E40),
    text: Color(0xFFE2E8F0), textDim: Color(0xFF94A3B8), muted: Color(0xFF64748B),
    isDark: true,
  ),
  AppThemeConfig(
    id: 'dark_gray', label: 'Cinza',
    accent: Color(0xFF94A3B8),
    bg: Color(0xFF0D0D0F), surface: Color(0xFF18181B),
    card: Color(0xFF1E1E24), border: Color(0xFF2D2D35),
    text: Color(0xFFE2E8F0), textDim: Color(0xFF94A3B8), muted: Color(0xFF64748B),
    isDark: true,
  ),
  AppThemeConfig(
    id: 'oled', label: 'OLED Preto',
    accent: Color(0xFF6366F1),
    bg: Color(0xFF000000), surface: Color(0xFF0D0D0D),
    card: Color(0xFF111111), border: Color(0xFF1F1F1F),
    text: Color(0xFFE2E8F0), textDim: Color(0xFF94A3B8), muted: Color(0xFF64748B),
    isDark: true,
  ),
  // ── Claros ──
  AppThemeConfig(
    id: 'light', label: 'Claro',
    accent: Color(0xFF6366F1),
    bg: Color(0xFFF1F5F9), surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF), border: Color(0xFFE2E8F0),
    text: Color(0xFF1E293B), textDim: Color(0xFF475569), muted: Color(0xFF64748B),
    isDark: false,
  ),
  AppThemeConfig(
    id: 'light_warm', label: 'Bege',
    accent: Color(0xFF92400E),
    bg: Color(0xFFFAF7F2), surface: Color(0xFFFFFDF8),
    card: Color(0xFFFFFDF8), border: Color(0xFFE7E0D5),
    text: Color(0xFF292118), textDim: Color(0xFF5C4F3D), muted: Color(0xFF8C7B6B),
    isDark: false,
  ),
];

AppThemeConfig themeById(String id) =>
    kThemes.firstWhere((t) => t.id == id, orElse: () => kThemes.first);

// ── Builder de ThemeData a partir de AppThemeConfig ───────
ThemeData buildTheme(AppThemeConfig t) {
  final base = t.isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  final scheme = t.isDark
      ? ColorScheme.dark(
          primary: t.accent, secondary: kGreen,
          surface: t.surface, error: kRed,
          onPrimary: Colors.white, onSurface: t.text)
      : ColorScheme.light(
          primary: t.accent, secondary: kGreen,
          surface: t.surface, error: kRed,
          onPrimary: Colors.white, onSurface: t.text);

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: t.bg,
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: t.text, displayColor: t.text,
      decorationColor: t.text),
    cardTheme: CardTheme(
      color: t.card, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: t.border, width: 1)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: t.card,
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.accent, width: 2)),
      labelStyle: TextStyle(color: t.muted),
      hintStyle:  TextStyle(color: t.muted),
      prefixStyle: TextStyle(color: t.text),
      suffixStyle: TextStyle(color: t.text),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      backgroundColor: t.accent, foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 14))),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.surface,
      indicatorColor: t.accent.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.all(TextStyle(fontSize: 11, color: t.text))),
    dividerTheme: DividerThemeData(color: t.border, thickness: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
    dialogTheme: DialogTheme(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    appBarTheme: AppBarTheme(
      backgroundColor: t.surface, foregroundColor: t.text, elevation: 0),
    popupMenuTheme: PopupMenuThemeData(color: t.surface),
    chipTheme: ChipThemeData(
      backgroundColor: t.card,
      side: BorderSide(color: t.border),
      labelStyle: TextStyle(color: t.text),
    ),
  );
}

// ── Atalhos legados (compatibilidade com código existente) ─
ThemeData appTheme() => buildTheme(kThemes[0]);
ThemeData appThemeLight() => buildTheme(kThemes[4]);

IconData iconData(String name) => _kIconMap[name] ?? Icons.more_horiz;

Color hexColor(String hex) {
  try { return Color(int.parse('0xFF${hex.replaceAll('#', '')}')); }
  catch (_) { return kPurple; }
}

const Map<String, IconData> _kIconMap = {
  'home': Icons.home_outlined, 'restaurant': Icons.restaurant_outlined,
  'directions_car': Icons.directions_car_outlined, 'favorite': Icons.favorite_outline,
  'school': Icons.school_outlined, 'celebration': Icons.celebration_outlined,
  'receipt_long': Icons.receipt_long_outlined, 'work': Icons.work_outline,
  'computer': Icons.computer_outlined, 'add_circle': Icons.add_circle_outline,
  'more_horiz': Icons.more_horiz, 'checkroom': Icons.checkroom_outlined,
  'attach_money': Icons.attach_money, 'trending_up': Icons.trending_up,
  'fitness_center': Icons.fitness_center_outlined, 'music_note': Icons.music_note_outlined,
  'local_cafe': Icons.local_cafe_outlined, 'sports_bar': Icons.sports_bar_outlined,
  'local_pharmacy': Icons.local_pharmacy_outlined, 'child_care': Icons.child_care_outlined,
  'flight': Icons.flight_outlined, 'smartphone': Icons.smartphone_outlined,
  'pets': Icons.pets_outlined, 'local_gas_station': Icons.local_gas_station_outlined,
  'local_hospital': Icons.local_hospital_outlined, 'lightbulb': Icons.lightbulb_outline,
  'card_giftcard': Icons.card_giftcard_outlined, 'fastfood': Icons.fastfood_outlined,
  'key': Icons.key_outlined, 'sports_esports': Icons.sports_esports_outlined,
};
