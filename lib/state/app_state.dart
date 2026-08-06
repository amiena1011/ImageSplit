// 全局应用状态 (SRS 4.6 模块7: UI主题系统 + 模块8: 本地持久化)
// 主题模式切换 + 持久化

import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../services/log_service.dart';

class AppState extends ChangeNotifier {
  final ConfigService _configService;
  final LogService _logService;

  ThemeMode _themeMode = ThemeMode.system;
  bool _initialized = false;

  AppState(this._configService, this._logService);

  ThemeMode get themeMode => _themeMode;
  bool get initialized => _initialized;

  /// 初始化加载持久化配置 (SRS 4.7)
  Future<void> init() async {
    final mode = await _configService.getThemeMode();
    _themeMode = ThemeMode.values[mode.clamp(0, 2)];
    _initialized = true;
    _logService.info('应用初始化完成');
    notifyListeners();
  }

  /// 切换主题模式 (SRS 4.6.2: 浅色/深色一键切换)
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _configService.setThemeMode(mode.index);
    _logService.info('主题切换为: ${mode.name}');
    notifyListeners();
  }
}
