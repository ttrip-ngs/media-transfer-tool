import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 2024-2025 最新UIトレンドを反映した超モダンテーマ
// 参考: Arc Browser, Linear, Raycast, Apple Vision Pro, Vercel

class UltraModernTheme {
  // Neutral colors - 真のモノクローム
  static const neutral950 = Color(0xFF030712); // ほぼ黒
  static const neutral900 = Color(0xFF111827);
  static const neutral800 = Color(0xFF1F2937);
  static const neutral700 = Color(0xFF374151);
  static const neutral600 = Color(0xFF4B5563);
  static const neutral500 = Color(0xFF6B7280);
  static const neutral400 = Color(0xFF9CA3AF);
  static const neutral300 = Color(0xFFD1D5DB);
  static const neutral200 = Color(0xFFE5E7EB);
  static const neutral100 = Color(0xFFF3F4F6);
  static const neutral50 = Color(0xFFF9FAFB);
  
  // Accent colors - 抑制された上品な色
  static const blue = Color(0xFF3B82F6);    // 控えめなブルー
  static const violet = Color(0xFF8B5CF6);  // 薄紫
  static const emerald = Color(0xFF10B981); // エメラルドグリーン
  static const amber = Color(0xFFF59E0B);   // アンバー
  static const rose = Color(0xFFF43F5E);    // ローズ
  
  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: neutral950,
      
      colorScheme: const ColorScheme.dark(
        background: neutral950,
        surface: neutral900,
        surfaceVariant: neutral800,
        primary: blue,
        secondary: violet,
        tertiary: emerald,
        error: rose,
        onBackground: neutral50,
        onSurface: neutral100,
        onPrimary: neutral50,
        onSecondary: neutral50,
      ),
      
      // シンプルで読みやすいタイポグラフィ
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w200,
          letterSpacing: -2,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w200,
          letterSpacing: -1.5,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w300,
          letterSpacing: -1,
          height: 1.2,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.5,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.5,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      
      // カード - フラットで境界線のみ
      cardTheme: CardThemeData(
        elevation: 0,
        color: neutral900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: neutral800,
            width: 1,
          ),
        ),
      ),
      
      // ボタン - フラットでミニマル
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: blue,
          foregroundColor: neutral50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neutral200,
          side: BorderSide(color: neutral700, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neutral300,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Input - クリーンでモダン
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutral900,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: neutral800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: neutral800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: blue, width: 2),
        ),
        hintStyle: TextStyle(color: neutral500),
        labelStyle: TextStyle(color: neutral400),
      ),
      
      // AppBar - 透明でフラット
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: neutral100,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: neutral100,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // その他
      dividerTheme: DividerThemeData(
        color: neutral800,
        thickness: 1,
        space: 1,
      ),
      
      iconTheme: IconThemeData(
        color: neutral300,
        size: 20,
      ),
      
      popupMenuTheme: PopupMenuThemeData(
        color: neutral900,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: neutral800),
        ),
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: neutral900,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: neutral800,
        contentTextStyle: TextStyle(color: neutral100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// スペーシングシステム - Tailwind CSS inspired
class Space {
  static const double xs = 2;   // 0.5rem
  static const double sm = 4;   // 1rem
  static const double md = 8;   // 2rem
  static const double lg = 12;  // 3rem
  static const double xl = 16;  // 4rem
  static const double xxl = 24; // 6rem
  static const double xxxl = 32; // 8rem
}

// ブレークポイント
class Breakpoint {
  static const double mobile = 640;
  static const double tablet = 768;
  static const double laptop = 1024;
  static const double desktop = 1280;
}

// アニメーション
class Motion {
  static const Duration fastest = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration slower = Duration(milliseconds: 500);
  
  static const Curve curve = Curves.easeInOutCubic;
  static const Curve curveIn = Curves.easeInCubic;
  static const Curve curveOut = Curves.easeOutCubic;
}