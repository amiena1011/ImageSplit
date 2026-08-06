// 操作日志服务 (SRS 4.5 模块6: 任务进度&日志&异常模块)
// 简易操作日志面板: 记录文件导入、参数配置、分割、导出、报错等全量操作记录

import 'package:flutter/foundation.dart';
import '../models/log_entry.dart';

class LogService extends ChangeNotifier {
  final List<LogEntry> _entries = [];
  static const int _maxEntries = 500;

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void info(String message, {String? detail}) =>
      _add(LogEntry(timestamp: DateTime.now(), level: LogLevel.info, message: message, detail: detail));

  void warning(String message, {String? detail}) =>
      _add(LogEntry(timestamp: DateTime.now(), level: LogLevel.warning, message: message, detail: detail));

  void error(String message, {String? detail}) =>
      _add(LogEntry(timestamp: DateTime.now(), level: LogLevel.error, message: message, detail: detail));

  void success(String message, {String? detail}) =>
      _add(LogEntry(timestamp: DateTime.now(), level: LogLevel.success, message: message, detail: detail));

  void _add(LogEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    // 调试输出
    if (kDebugMode) print(entry);
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
