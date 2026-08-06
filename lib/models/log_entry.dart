// 操作日志条目模型 (SRS 4.5 任务进度&日志&异常模块)
// 记录文件导入、参数配置、分割、导出、报错等全量操作记录

import 'package:flutter/foundation.dart';

/// 日志级别
enum LogLevel { info, warning, error, success }

/// 操作日志条目
class LogEntry with ChangeNotifier {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? detail;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.detail,
  });

  /// 图标标识
  String get levelIcon => switch (level) {
        LogLevel.info => 'ℹ',
        LogLevel.warning => '⚠',
        LogLevel.error => '✕',
        LogLevel.success => '✓',
      };

  /// 格式化时间
  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  String toString() => '[${timeFormatted}] ${levelIcon} $message';
}
