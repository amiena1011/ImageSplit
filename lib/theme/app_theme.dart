// Material3 主题系统模块 (SRS 4.6 / 模块7)
// 全量采用 Flutter Material3 原生控件, 双端样式统一
// 支持浅色模式、深色模式一键切换, 主题偏好自动持久化

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  /// 浅色主题 - Material3 默认 seedColor
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F6BED),
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          clipBehavior: Clip.antiAlias,
        ),
        dividerTheme: const DividerThemeData(
          space: 1,
          thickness: 1,
        ),
      );

  /// 深色主题
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F6BED),
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          clipBehavior: Clip.antiAlias,
        ),
        dividerTheme: const DividerThemeData(
          space: 1,
          thickness: 1,
        ),
      );
}
