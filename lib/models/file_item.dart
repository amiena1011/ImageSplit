// 导入文件数据模型 (SRS 4.1 文件上传&文件列表管理模块)
// 对应模块1: 文件上传&文件列表管理

import 'package:flutter/foundation.dart';

/// 文件类型枚举
enum FileItemType {
  image,        // 普通图片
  pdfConverted  // 从PDF转换的图片
}

/// 文件加载状态 (SRS 4.1.4 导入预校验: 超大图片加载实时展示进度)
enum FileItemStatus {
  pending,    // 等待处理
  loading,    // 加载中
  ready,      // 就绪
  error,      // 损坏/错误
}

/// 导入文件模型
class FileItem with ChangeNotifier {
  final String id;
  final String path;           // 原始文件路径 (只读, 不修改源文件 SRS 7.2)
  final String name;
  final int sizeBytes;
  FileItemType type;
  DateTime addedAt;

  FileItemStatus status;
  String? errorMessage;
  double? loadProgress;        // 0.0 ~ 1.0, 大图加载进度

  // 图片元数据 (加载完成后填充)
  int? imageWidth;
  int? imageHeight;

  // PDF转换信息
  int? pdfPageNumber;  // PDF页码 (从1开始)

  FileItem({
    required this.id,
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.type,
    required this.addedAt,
    this.status = FileItemStatus.pending,
    this.errorMessage,
    this.loadProgress,
    this.imageWidth,
    this.imageHeight,
    this.pdfPageNumber,
  });

  /// 扩展名 (小写)
  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return '';
    return name.substring(dot).toLowerCase();
  }

  /// 是否图片
  bool get isImage => true;

  /// 是否从PDF转换的图片
  bool get isPdfConverted => type == FileItemType.pdfConverted;

  /// 格式化文件大小
  String get sizeFormatted {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = sizeBytes.toDouble();
    int unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  /// 从路径推断文件类型
  static FileItemType typeFromExtension(String ext) => FileItemType.image;

  /// 序列化为 JSON (用于 SRS 4.7 持久化保存文件列表)
  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'name': name,
        'sizeBytes': sizeBytes,
        'type': type.name,
        'addedAt': addedAt.toIso8601String(),
        'pdfPageNumber': pdfPageNumber,
      };

  factory FileItem.fromJson(Map<String, dynamic> json) => FileItem(
        id: json['id'] as String,
        path: json['path'] as String,
        name: json['name'] as String,
        sizeBytes: json['sizeBytes'] as int,
        type: FileItemType.values.byName(json['type'] as String),
        addedAt: DateTime.parse(json['addedAt'] as String),
        pdfPageNumber: json['pdfPageNumber'] as int?,
      );

  /// 创建PDF转换的文件项
  static FileItem createPdfConverted({
    required String id,
    required String path,
    required String name,
    required int sizeBytes,
    required int pageNumber,
    DateTime? addedAt,
  }) {
    return FileItem(
      id: id,
      path: path,
      name: name,
      sizeBytes: sizeBytes,
      type: FileItemType.pdfConverted,
      addedAt: addedAt ?? DateTime.now(),
      pdfPageNumber: pageNumber,
    );
  }

  @override
  String toString() => 'FileItem($name, $type, ${sizeFormatted})';
}
