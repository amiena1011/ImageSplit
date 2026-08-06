// 导出输出服务 (SRS 4.3 模块4: 导出输出配置模块)
// 标准化文件命名: 时间戳+原文件名+随机编码+子图编号 (SRS 4.3.2)
// 双文件夹切片输出策略 (SRS 4.3.4 模式A/B)
// PDF 合并留白、统一尺寸 (SRS 4.3.4 / 4.4.2)
// 原始文件只读 (SRS 7.2)

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/export_config.dart';
import '../models/file_item.dart';
import '../models/split_config.dart';
import 'image_split_service.dart';
import 'pdf_service.dart';

class ExportService {
  final _uuid = const Uuid();
  final ImageSplitService _splitService = ImageSplitService();
  final PdfService _pdfService = PdfService();

  /// 执行导出任务
  ///
  /// [files] 排序后的文件列表 (顺序决定输出顺序 SRS 4.1.4)
  /// [configs] 每个文件对应的分割配置 (fileId -> config)
  /// [onProgress] 总进度 0.0~1.0
  /// [onLog] 日志回调
  Future<ExportResult> export({
    required List<FileItem> files,
    required Map<String, SplitConfig> configs,
    required ExportConfig exportConfig,
    void Function(double, String)? onProgress,
    void Function(String, {bool error})? onLog,
  }) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final taskDir = Directory(_joinPath(exportConfig.outputDir, 'split_$timestamp'));
    await taskDir.create(recursive: true);

    final allSlices = <SliceResult>[];
    final outputFiles = <String>[];
    var processed = 0;
    final total = files.length;

    for (final file in files) {
      final config = configs[file.id];
      if (config == null) {
        onLog?.call('跳过无配置文件: ${file.name}', error: true);
        processed++;
        continue;
      }

      // Feature #7: PDF 分割暂不可用, 跳过 (已移除 PDF 支持)


      onProgress?.call(processed / total, '正在分割: ${file.name}');
      onLog?.call('开始分割: ${file.name} (${config.rows}×${config.cols})');

      // 确定该文件的输出文件夹
      Directory sliceDir;
      if (exportConfig.mergePdf) {
        sliceDir = taskDir; // 合并模式统一存放
      } else if (exportConfig.folderStrategy == SliceFolderStrategy.perImage) {
        // 模式A: 每张原图独立文件夹
        final baseName = _baseName(file.name);
        sliceDir = Directory(_joinPath(taskDir.path, '${baseName}_slices'));
        await sliceDir.create(recursive: true);
      } else {
        sliceDir = taskDir; // 模式B: 统一文件夹
      }

      try {
        final slices = _splitService.splitImage(
          file: file,
          config: config,
          format: exportConfig.formatLabel.toLowerCase(),
          quality: exportConfig.quality,
        );
        await for (final slice in slices) {
          final baseName = _baseName(file.name);
          final randCode = _uuid.v4().substring(0, 6);
          // SRS 4.3.2: 时间戳+原文件名+随机编码+子图编号
          final outName =
              '${timestamp}_${baseName}_${randCode}_${slice.index + 1}${exportConfig.extension}';
          final outFile = File(_joinPath(sliceDir.path, outName));
          await outFile.writeAsBytes(slice.bytes);
          outputFiles.add(outFile.path);
          allSlices.add(slice);
          onLog?.call('导出切片: $outName');
        }
      } catch (e) {
        onLog?.call('分割失败: ${file.name} - $e', error: true);
      }

      processed++;
      onProgress?.call(processed / total, '完成: ${file.name}');
    }

    // PDF 合并导出 (SRS 4.3.4 开启合并PDF)
    if (exportConfig.mergePdf && allSlices.isNotEmpty) {
      onLog?.call('开始合并 PDF...');
      final pdfName = 'merged_$timestamp.pdf';
      final pdfPath = _joinPath(taskDir.path, pdfName);
      try {
        await _pdfService.mergeToPdf(
          slices: allSlices,
          outputPath: pdfPath,
          dpi: exportConfig.pdfDpi,
        );
        outputFiles.add(pdfPath);
        onLog?.call('PDF 合并完成: $pdfName');
      } catch (e) {
        onLog?.call('PDF 合并失败: $e', error: true);
      }
    }

    onProgress?.call(1.0, '导出完成');
    return ExportResult(
      taskDir: taskDir.path,
      files: outputFiles,
      sliceCount: allSlices.length,
    );
  }

  String _baseName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }

  String _joinPath(String dir, String name) {
    if (dir.endsWith('\\') || dir.endsWith('/')) return '$dir$name';
    return '$dir${Platform.pathSeparator}$name';
  }
}

/// 导出结果
class ExportResult {
  final String taskDir;
  final List<String> files;
  final int sliceCount;

  ExportResult({
    required this.taskDir,
    required this.files,
    required this.sliceCount,
  });
}
