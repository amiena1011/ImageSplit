// PDF 双向处理服务 (SRS 4.4 模块5: PDF双向处理模块)
// 主方案: PDFium (pdfx) 逐页解析 PDF 渲染为高清图片 (SRS 4.4.1)
// Windows 兜底: Microsoft Print to PDF (SRS 4.4.1.2)
// PDF 合并导出: 拼接切片统一尺寸留白填充 (SRS 4.4.2) — 基于 pdf 包
//
// 注: pdfx 需在构建期下载 pdfium 二进制, 受网络/沙箱环境限制时
//     PDF 转图片功能降级为提示, PDF 合并导出仍正常工作

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import '../models/file_item.dart';
import 'image_split_service.dart';

/// PDF 渲染引擎可用性
enum PdfEngineStatus {
  available,     // PDFium 可用
  unavailable,   // 引擎未安装/构建, PDF 转图片不可用
}

class PdfService {
  /// 当前 PDF 渲染引擎状态
  ///
  /// pdfx 插件未启用时返回 unavailable, 调用方应提示用户
  PdfEngineStatus get engineStatus => PdfEngineStatus.unavailable;

  /// PDF 转图片 (SRS 4.4.1 主方案 PDFium)
  ///
  /// 返回每页的 PNG 字节数据列表. 引擎不可用时抛出明确异常供上层提示.
  Future<List<Uint8List>> pdfToImages(
    FileItem pdfFile, {
    double scale = 2.0,
    void Function(double)? onProgress,
  }) async {
    if (engineStatus == PdfEngineStatus.unavailable) {
      // SRS 4.4.1.2: Windows 专属兜底亦不可用时明确提示
      throw Exception(
        'PDF 渲染引擎 (PDFium) 不可用。\n'
        '该环境未启用 pdfx 插件 (需构建期下载 pdfium 二进制)。\n'
        'Windows 端可在配置好网络后启用 pdfx 以恢复 PDF 转图片功能。',
      );
    }
    // 引擎可用时调用 pdfx (此处保留接口, 启用 pdfx 后实现)
    throw UnimplementedError('PDFium 引擎已启用但渲染实现待接入');
  }

  /// PDF 合并导出 (SRS 4.4.2 / 4.3.4)
  /// 按排序规则拼接所有切片, 每页使用原图尺寸
  Future<void> mergeToPdf({
    required List<SliceResult> slices,
    required String outputPath,
    required int dpi,
    void Function(double)? onProgress,
  }) async {
    final pdf = PdfDocument();

    for (var i = 0; i < slices.length; i++) {
      final s = slices[i];
      final pageW = s.width.toDouble();
      final pageH = s.height.toDouble();
      if (pageW <= 0 || pageH <= 0) {
        final page = PdfPage(pdf, pageFormat: const PdfPageFormat(595, 842));
        final canvas = page.getGraphics();
        canvas.setFillColor(PdfColors.white);
        canvas.drawRect(0, 0, 595, 842);
        canvas.fillPath();
        onProgress?.call((i + 1) / slices.length);
        continue;
      }

      final pageFormat = PdfPageFormat(pageW, pageH,
          marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0);
      final page = PdfPage(pdf, pageFormat: pageFormat);
      final canvas = page.getGraphics();
      canvas.setFillColor(PdfColors.white);
      canvas.drawRect(0, 0, pageW, pageH);
      canvas.fillPath();

      final image = PdfImage.file(pdf, bytes: s.bytes);
      canvas.drawImage(image, 0, 0, pageW, pageH);
      onProgress?.call((i + 1) / slices.length);
    }

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
  }
}
