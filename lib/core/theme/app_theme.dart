import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF1565C0);

  // Couleurs sémantiques CardLock
  static const colorOccupied      = Color(0xFFE24B4A);
  static const colorOccupiedLight = Color(0xFFFCEBEB);
  static const colorVacant        = Color(0xFF639922);
  static const colorVacantLight   = Color(0xFFEAF3DE);
  static const colorCard          = Color(0xFF185FA5);
  static const colorCardLight     = Color(0xFFE6F1FB);
  static const colorErased        = Color(0xFF5F5E5A);
  static const colorErasedLight   = Color(0xFFF1EFE8);

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: const Color(0xFFF5F6F8),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: cs.primaryContainer,
        selectedIconTheme: IconThemeData(color: cs.onPrimaryContainer),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF6B7280)),
        selectedLabelTextStyle: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
        ),
        elevation: 0,
        labelType: NavigationRailLabelType.all,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _seedColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Color(0xFF6B7280),
          letterSpacing: 0.3,
        ),
        dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
        dividerThickness: 0.5,
        horizontalMargin: 16,
        columnSpacing: 20,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 0.5,
        space: 0,
      ),
      appBarTheme: const AppBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFF111827),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Color(0xFF374151)),
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: 'Segoe UI',
    );
  }
}
