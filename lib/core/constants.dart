// 核心常量定义 - 支持格式、预设、应用级配置
// 对应 SRS: 4.1.1 支持文件格式 / 4.2.1 系统内置预设 / 4.7 本地持久化配置

import 'package:flutter/foundation.dart';

/// 应用全局常量
class AppConstants {
  AppConstants._();

  static const String appName = '图片分割预览与PDF合成工具';
  static const String appVersion = '1.0.0';

  /// 支持的图片格式 (SRS 4.1.1)
  static const List<String> supportedExtensions = [
    '.png', '.jpg', '.jpeg', '.bmp', '.tif', '.tiff',
  ];

  /// 系统内置预设 (SRS 4.2.1: 1×2、2×1、1×3、3×1, 默认常驻不可删除)
  static const List<SplitPresetBuiltIn> builtInPresets = [
    SplitPresetBuiltIn('1×2', 1, 2),
    SplitPresetBuiltIn('2×1', 2, 1),
    SplitPresetBuiltIn('1×3', 1, 3),
    SplitPresetBuiltIn('3×1', 3, 1),
  ];

  /// 导出支持格式 (SRS 4.3.3)
  static const List<String> exportFormats = ['PNG', 'JPG', 'BMP', 'TIFF'];

  /// SharedPreferences 键名
  static const String keyThemeMode = 'theme_mode';
  static const String keyCustomPresets = 'custom_presets';
  static const String keyLastOutputPath = 'last_output_path';
  static const String keyKeepFileList = 'keep_file_list';
  static const String keySavedFileList = 'saved_file_list';
}

/// 系统内置预设数据结构
class SplitPresetBuiltIn {
  final String name;
  final int rows;
  final int cols;
  const SplitPresetBuiltIn(this.name, this.rows, this.cols);
}

/// 平台判断工具 (SRS 2: 平台差异化)
class PlatformUtils {
  PlatformUtils._();

  static bool get isWindows => defaultTargetPlatform == TargetPlatform.windows;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isDesktop => isWindows || kIsWeb == false && defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS;
  static bool get isMobile => isAndroid || defaultTargetPlatform == TargetPlatform.iOS;

  /// 当前平台名称
  static String get platformName {
    if (isWindows) return 'Windows';
    if (isAndroid) return 'Android';
    return 'Other';
  }
}
