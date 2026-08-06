// 导出输出配置模型 (SRS 4.3 导出输出配置模块)
// 输出路径、命名规则、格式画质、PDF合并双模式

import 'package:flutter/foundation.dart';

/// 导出格式 (SRS 4.3.3)
enum ExportFormat { png, jpg, bmp, tiff }

/// 切片输出文件夹策略 (SRS 4.3.4 关闭合并PDF时)
enum SliceFolderStrategy {
  perImage,  // 模式A: 每张原图切片独立分配专属文件夹
  unified,   // 模式B: 本次所有切片统一存入同一个任务文件夹
}

/// 导出配置
class ExportConfig with ChangeNotifier {
  /// 输出目录路径 (Windows 可自定义; Android 固定下载目录)
  String outputDir;

  /// 导出格式
  ExportFormat format;

  /// 画质 (0-100, 仅 JPG/PNG 可调; TIFF 无损置灰 SRS 4.3.3)
  int quality;

  /// 是否合并为 PDF (SRS 4.3.4 二选一)
  bool mergePdf;

  /// PDF 输出分辨率 (DPI)
  int pdfDpi;

  /// PDF 压缩等级 (0-9)
  int pdfCompression;

  /// 切片文件夹策略 (非合并 PDF 模式)
  SliceFolderStrategy folderStrategy;

  ExportConfig({
    this.outputDir = '',
    this.format = ExportFormat.png,
    this.quality = 90,
    this.mergePdf = false,
    this.pdfDpi = 150,
    this.pdfCompression = 6,
    this.folderStrategy = SliceFolderStrategy.perImage,
  });

  /// TIFF 是否可调整画质 (SRS 4.3.3: 固定无损输出, 画质参数置灰)
  bool get qualityEditable => format != ExportFormat.tiff;

  /// 格式扩展名
  String get extension => switch (format) {
        ExportFormat.png => '.png',
        ExportFormat.jpg => '.jpg',
        ExportFormat.bmp => '.bmp',
        ExportFormat.tiff => '.tiff',
      };

  /// 格式显示名
  String get formatLabel => switch (format) {
        ExportFormat.png => 'PNG',
        ExportFormat.jpg => 'JPG',
        ExportFormat.bmp => 'BMP',
        ExportFormat.tiff => 'TIFF',
      };

  Map<String, dynamic> toJson() => {
        'outputDir': outputDir,
        'format': format.name,
        'quality': quality,
        'mergePdf': mergePdf,
        'pdfDpi': pdfDpi,
        'pdfCompression': pdfCompression,
        'folderStrategy': folderStrategy.name,
      };

  factory ExportConfig.fromJson(Map<String, dynamic> json) => ExportConfig(
        outputDir: json['outputDir'] as String? ?? '',
        format: ExportFormat.values.byName(json['format'] as String? ?? 'png'),
        quality: json['quality'] as int? ?? 90,
        mergePdf: json['mergePdf'] as bool? ?? false,
        pdfDpi: json['pdfDpi'] as int? ?? 150,
        pdfCompression: json['pdfCompression'] as int? ?? 6,
        folderStrategy: SliceFolderStrategy.values
            .byName(json['folderStrategy'] as String? ?? 'perImage'),
      );
}
