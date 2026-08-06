// 分割配置数据模型 (SRS 4.2 分割预览与参数配置模块)
// 快速配置: 等分分割 (rows × cols)
// 手动微调: 分割线位置可拖拽调整

import 'package:flutter/foundation.dart';

/// 分割模式 (两种业务流程)
enum SplitMode {
  quick,       // 极简流程: 仅快速配置, 全局等分
  soloTune,    // 独立微调流程: 逐张独立微调, 适配不同尺寸
}

/// 单张图片的分割配置
///
/// 等分模式: rows × cols 自动生成等距分割线
/// 微调模式: 用户拖拽调整每条分割线的位置 (归一化坐标 0.0~1.0)
class SplitConfig with ChangeNotifier {
  final String fileId;

  int rows;
  int cols;

  /// 水平分割线位置 (归一化, 长度 = rows-1)
  /// 例如 2 行: [0.5] 表示中间一条线在 50% 位置
  List<double> hLines;

  /// 垂直分割线位置 (归一化, 长度 = cols-1)
  List<double> vLines;

  SplitConfig({
    required this.fileId,
    this.rows = 1,
    this.cols = 2,
    List<double>? hLines,
    List<double>? vLines,
  })  : hLines = hLines ?? _evenLines(rows),
        vLines = vLines ?? _evenLines(cols);

  /// 生成等距分割线 (SRS 4.2.1 快速配置全局等分)
  static List<double> _evenLines(int count) {
    if (count <= 1) return [];
    return List.generate(count - 1, (i) => (i + 1) / count);
  }

  /// 重新设置行列数, 自动重置为等距分割线
  void setGrid(int newRows, int newCols) {
    rows = newRows;
    cols = newCols;
    hLines = _evenLines(newRows);
    vLines = _evenLines(newCols);
    notifyListeners();
  }

  /// 设置水平分割线位置 (SRS 4.2.2 手动微调)
  void setHLine(int index, double value) {
    if (index >= 0 && index < hLines.length) {
      hLines[index] = value.clamp(0.02, 0.98);
      notifyListeners();
    }
  }

  /// 设置垂直分割线位置
  void setVLine(int index, double value) {
    if (index >= 0 && index < vLines.length) {
      vLines[index] = value.clamp(0.02, 0.98);
      notifyListeners();
    }
  }

  /// 全部水平分界坐标 (含 0.0 和 1.0 边界)
  List<double> get hBounds => [0.0, ...hLines, 1.0];

  /// 全部垂直分界坐标 (含 0.0 和 1.0 边界)
  List<double> get vBounds => [0.0, ...vLines, 1.0];

  /// 总切片数
  int get totalSlices => rows * cols;

  /// 获取第 i 个切片的归一化区域 (x0, y0, x1, y1)
  /// 排序规则 (SRS 4.3.4): 单张原图先行后列输出全部切片
  /// i = row * cols + col
  ({double x0, double y0, double x1, double y1}) sliceRect(int i) {
    final row = i ~/ cols;
    final col = i % cols;
    return (
      x0: vBounds[col],
      y0: hBounds[row],
      x1: vBounds[col + 1],
      y1: hBounds[row + 1],
    );
  }

  /// 复制配置 (用于同步至其他图片 SRS 4.2.2)
  SplitConfig copy() => SplitConfig(
        fileId: fileId,
        rows: rows,
        cols: cols,
        hLines: List<double>.from(hLines),
        vLines: List<double>.from(vLines),
      );

  /// 从另一配置同步参数
  void syncFrom(SplitConfig other) {
    rows = other.rows;
    cols = other.cols;
    hLines = List<double>.from(other.hLines);
    vLines = List<double>.from(other.vLines);
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'fileId': fileId,
        'rows': rows,
        'cols': cols,
        'hLines': hLines,
        'vLines': vLines,
      };

  factory SplitConfig.fromJson(Map<String, dynamic> json) => SplitConfig(
        fileId: json['fileId'] as String,
        rows: json['rows'] as int,
        cols: json['cols'] as int,
        hLines: (json['hLines'] as List).cast<double>(),
        vLines: (json['vLines'] as List).cast<double>(),
      );
}
