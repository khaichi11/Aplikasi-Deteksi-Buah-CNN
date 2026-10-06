import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Warna Buah-Seru: ungu dan hijau seperti versi awal aplikasi, ditambah
/// krem apel dan merah ulat dari logo. Datar, tanpa gradien.
class AppColors {
  static const Color background = Color(0xFFF7F5FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE7E1EF);

  static const Color ink = Color(0xFF221B2E);
  static const Color inkSoft = Color(0xFF6B6478);

  /// Ungu utama (sama dengan header versi awal).
  static const Color purple = Color(0xFF673AB7);
  static const Color purpleSoft = Color(0xFFEDE5F8);

  /// Hijau untuk jawaban benar dan hal positif.
  static const Color leaf = Color(0xFF2E9D57);
  static const Color leafSoft = Color(0xFFDFF3E6);

  /// Krem apel dari logo, untuk poin dan sorotan.
  static const Color apple = Color(0xFFFDDC8F);
  static const Color appleSoft = Color(0xFFFFF4D6);

  /// Merah ulat dari logo, hanya untuk jawaban yang salah.
  static const Color worm = Color(0xFFE5484D);
  static const Color wormSoft = Color(0xFFFDE4E4);
}

class AppFonts {
  static const String display = 'Poppins';
  static const String body = 'Inter';
}

TextStyle displayStyle({
  double size = 20,
  Color color = AppColors.ink,
  FontWeight weight = FontWeight.w700,
}) =>
    TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: 1.2,
    );

TextStyle numberStyle({
  double size = 20,
  Color color = AppColors.ink,
  FontWeight weight = FontWeight.w700,
}) =>
    TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      color: color,
      fontWeight: weight,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: AppFonts.body,
    colorScheme: const ColorScheme.light(
      primary: AppColors.purple,
      onPrimary: Colors.white,
      secondary: AppColors.leaf,
      onSecondary: Colors.white,
      error: AppColors.worm,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
    ),
  );
  const r = BorderRadius.all(Radius.circular(14));
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.purple,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 54),
        textStyle: const TextStyle(fontFamily: AppFonts.display, fontWeight: FontWeight.w600, fontSize: 16),
        shape: const RoundedRectangleBorder(borderRadius: r),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(0, 54),
        side: const BorderSide(color: AppColors.line, width: 1.5),
        backgroundColor: AppColors.surface,
        textStyle: const TextStyle(fontFamily: AppFonts.display, fontWeight: FontWeight.w600, fontSize: 16),
        shape: const RoundedRectangleBorder(borderRadius: r),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.purple,
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1, thickness: 1),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: r),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.purple),
  );
}
