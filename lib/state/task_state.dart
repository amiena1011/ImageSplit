// 任务进度状态 (SRS 4.5 模块6: 任务进度、日志、异常提示模块)
// 全局任务进度条: 分割、导出、PDF转换全流程实时展示百分比进度

import 'package:flutter/foundation.dart';

class TaskState extends ChangeNotifier {
  bool _running = false;
  double _progress = 0.0;
  String _statusText = '';
  String _errorText = '';

  bool get running => _running;
  double get progress => _progress;
  String get statusText => _statusText;
  String get errorText => _errorText;
  bool get hasError => _errorText.isNotEmpty;

  /// 进度百分比 0~100
  int get progressPercent => (progress * 100).round();

  void start(String status) {
    _running = true;
    _progress = 0.0;
    _statusText = status;
    _errorText = '';
    notifyListeners();
  }

  void update(double progress, String status) {
    _progress = progress;
    _statusText = status;
    notifyListeners();
  }

  void finish(String status) {
    _progress = 1.0;
    _statusText = status;
    _running = false;
    notifyListeners();
  }

  void error(String message) {
    _errorText = message;
    _running = false;
    notifyListeners();
  }

  void reset() {
    _running = false;
    _progress = 0.0;
    _statusText = '';
    _errorText = '';
    notifyListeners();
  }
}
