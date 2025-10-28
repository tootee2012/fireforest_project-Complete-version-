import 'package:flutter/material.dart';

class AppTheme {
  // ✅ สีหลักสีส้ม (เหมือนในรูป)
  static const Color primaryColor = Color(0xFFFF9800); // ส้มหลัก
  static const Color primaryDark = Color(0xFFF57C00); // ส้มเข้ม
  static const Color primaryLight = Color(0xFFFFC107); // ส้มอ่อน
  static const Color accent = Color(0xFFFFB74D); // ส้มอ่อนกว่า

  // ✅ สีพื้นหลัง
  static const Color backgroundColor = Color(0xFFFFF3E0); // ครีมส้มอ่อน
  static const Color cardBackground = Colors.white;
  static const Color surfaceColor = Color(0xFFFFF8F0); // ขาวครีม

  // ✅ สีข้อความ
  static const Color textPrimary = Color(0xFF2E2E2E);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Colors.white;

  // ✅ สีสถานะ
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // ✅ สีเงา
  static Color shadowColor = primaryColor.withOpacity(0.15);
  static Color borderColor = primaryColor.withOpacity(0.3);

  // ✅ Gradient สี
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundColor, surfaceColor],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ✅ Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      primarySwatch: MaterialColor(primaryColor.value, <int, Color>{
        50: Color(0xFFFFF8F0),
        100: Color(0xFFFFECB3),
        200: Color(0xFFFFE082),
        300: Color(0xFFFFD54F),
        400: Color(0xFFFFCA28),
        500: primaryColor,
        600: Color(0xFFFFA000),
        700: Color(0xFFFF8F00),
        800: Color(0xFFFF8A65),
        900: primaryDark,
      }),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Kanit',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textOnPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return null;
        }),
      ),
    );
  }
}

// ✅ Widget Extensions สำหรับ Theme
extension AppThemeExtension on BuildContext {
  Color get primaryColor => AppTheme.primaryColor;
  Color get backgroundColor => AppTheme.backgroundColor;
  Color get cardBackground => AppTheme.cardBackground;
  Color get textPrimary => AppTheme.textPrimary;
  Color get textSecondary => AppTheme.textSecondary;
}
