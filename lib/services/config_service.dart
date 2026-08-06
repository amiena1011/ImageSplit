// 本地配置持久化服务 (SRS 4.7 本地持久化配置模块 / 模块8)
// 使用 shared_preferences 持久化: 主题、自定义预设、输出路径、文件列表偏好
// 对应 SRS 4.7: 程序关闭自动保存, 永久生效

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/split_preset.dart';

class ConfigService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ---------- 主题模式 ----------
  /// 0=system, 1=light, 2=dark
  Future<int> getThemeMode() async =>
      (await prefs).getInt(AppConstants.keyThemeMode) ?? 0;

  Future<void> setThemeMode(int mode) async =>
      (await prefs).setInt(AppConstants.keyThemeMode, mode);

  // ---------- 自定义分割预设 (SRS 4.2.1) ----------
  Future<List<SplitPreset>> getCustomPresets() async {
    final raw = (await prefs).getString(AppConstants.keyCustomPresets);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SplitPreset.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setCustomPresets(List<SplitPreset> presets) async {
    final raw = jsonEncode(presets.map((p) => p.toJson()).toList());
    await (await prefs).setString(AppConstants.keyCustomPresets, raw);
  }

  // ---------- 输出路径 (SRS 4.3.1: Windows 记忆上次输出路径) ----------
  Future<String> getLastOutputPath() async =>
      (await prefs).getString(AppConstants.keyLastOutputPath) ?? '';

  Future<void> setLastOutputPath(String path) async =>
      (await prefs).setString(AppConstants.keyLastOutputPath, path);

  // ---------- 退出列表保存偏好 (SRS 4.1.5 / 4.7) ----------
  Future<bool> getKeepFileList() async =>
      (await prefs).getBool(AppConstants.keyKeepFileList) ?? false;

  Future<void> setKeepFileList(bool keep) async =>
      (await prefs).setBool(AppConstants.keyKeepFileList, keep);

  // ---------- 文件列表持久化 (SRS 4.1.5 退出保存逻辑) ----------
  Future<List<Map<String, dynamic>>> getSavedFileList() async {
    final raw = (await prefs).getString(AppConstants.keySavedFileList);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> setSavedFileList(List<Map<String, dynamic>> files) async {
    final raw = jsonEncode(files);
    await (await prefs).setString(AppConstants.keySavedFileList, raw);
  }

  Future<void> clearSavedFileList() async =>
      (await prefs).remove(AppConstants.keySavedFileList);
}
