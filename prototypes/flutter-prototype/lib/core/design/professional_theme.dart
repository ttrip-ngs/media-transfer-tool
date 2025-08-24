import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// プロフェッショナルグレードのテーマ
// Adobe Lightroom Classic, Capture One, DaVinci Resolve レベルの品質

class ProTheme {
  // Professional color palette - 彩度を抑えた信頼感のある色
  static const background = Color(0xFF1A1A1A);    // ほぼ黒だが完全な黒ではない
  static const surface = Color(0xFF242424);       // パネル背景
  static const surfaceLight = Color(0xFF2A2A2A);  // ホバー時
  static const border = Color(0xFF3A3A3A);        // ボーダー
  static const borderLight = Color(0xFF4A4A4A);   // 強調ボーダー
  
  // Text colors
  static const textPrimary = Color(0xFFE0E0E0);   // メインテキスト
  static const textSecondary = Color(0xFFA0A0A0); // サブテキスト
  static const textDisabled = Color(0xFF606060);  // 無効テキスト
  
  // Accent colors - 控えめで professional
  static const accent = Color(0xFF4A90E2);        // 落ち着いた青
  static const accentHover = Color(0xFF5BA0F2);   // ホバー時
  static const success = Color(0xFF5CB85C);       // 成功
  static const warning = Color(0xFFF0AD4E);       // 警告
  static const error = Color(0xFFD9534F);         // エラー
  
  static ThemeData theme() {
    return ThemeData(
      useMaterial3: false, // Material 2 の方がプロフェッショナル
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      
      colorScheme: const ColorScheme.dark(
        background: background,
        surface: surface,
        primary: accent,
        secondary: accent,
        error: error,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),
      
      // Typography - 読みやすく professional
      fontFamily: 'Segoe UI', // Windows標準
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),
      
      // Buttons - フラットで professional
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: border,
          disabledForegroundColor: textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4), // 最小限の角丸
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      
      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: accent, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: const TextStyle(color: textDisabled, fontSize: 13),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
      ),
      
      // Cards - minimal
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Dividers
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      
      // Icons
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 18,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Tooltips
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border),
        ),
        textStyle: const TextStyle(
          color: textPrimary,
          fontSize: 11,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        preferBelow: false,
      ),
      
      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      
      // Menus
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: border),
        ),
      ),
      
      // Scrollbar
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(borderLight),
        trackColor: MaterialStateProperty.all(surface),
        thickness: MaterialStateProperty.all(8),
        radius: const Radius.circular(0),
      ),
    );
  }
}

// Spacing constants - 密度の高いレイアウト
class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}