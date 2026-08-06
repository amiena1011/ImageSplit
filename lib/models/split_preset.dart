// 分割预设数据模型 (SRS 4.2.1 快速配置模式)
// 系统内置预设: 1×2、2×1、1×3、3×1 (常驻不可删除)
// 自定义预设: 用户新增、保存、删除

import 'package:flutter/foundation.dart';

/// 分割预设
class SplitPreset with ChangeNotifier {
  final String id;
  final String name;
  final int rows;       // 横向分割份数
  final int cols;       // 纵向分割份数
  final bool isBuiltIn; // 系统内置 (不可删除)

  SplitPreset({
    required this.id,
    required this.name,
    required this.rows,
    required this.cols,
    this.isBuiltIn = false,
  });

  /// 总切片数
  int get totalSlices => rows * cols;

  /// 描述文本, 如 "2行 × 3列 = 6块"
  String get description => '$rows行 × $cols列 = ${totalSlices}块';

  /// 预设标识
  String get label => name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rows': rows,
        'cols': cols,
        'isBuiltIn': isBuiltIn,
      };

  factory SplitPreset.fromJson(Map<String, dynamic> json) => SplitPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        rows: json['rows'] as int,
        cols: json['cols'] as int,
        isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitPreset && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
