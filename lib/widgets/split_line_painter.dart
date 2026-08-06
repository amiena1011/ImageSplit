// 分割线绘制器 (SRS 4.2/4.3 模块3: 预览画布交互模块)
// 优化: 直接接收线值而非 config 对象, 解决 shouldRepaint 不触发的问题
// 绘制等分分割线, 支持手动微调的可拖拽分割线

import 'package:flutter/material.dart';

class SplitLinePainter extends CustomPainter {
  final int rows;
  final int cols;
  final List<double> hLines;
  final List<double> vLines;
  final int? draggingH;
  final int? draggingV;
  final bool draggable;

  SplitLinePainter({
    required this.rows,
    required this.cols,
    required this.hLines,
    required this.vLines,
    this.draggingH,
    this.draggingV,
    this.draggable = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 切片背景网格
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final hBounds = <double>[0.0, ...hLines, 1.0];
    final vBounds = <double>[0.0, ...vLines, 1.0];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x0 = vBounds[c] * w;
        final y0 = hBounds[r] * h;
        final x1 = vBounds[c + 1] * w;
        final y1 = hBounds[r + 1] * h;
        if ((r + c) % 2 == 0) {
          canvas.drawRect(Rect.fromLTRB(x0, y0, x1, y1), gridPaint);
        }
      }
    }

    // 分割线 - 快速模式用灰色虚线, 微调模式用红色实线
    final linePaint = Paint()
      ..color = draggable ? Colors.red.withValues(alpha: 0.9) : Colors.grey.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // 快速模式: 不绘制拖拽手柄 (圆点)
    // 微调模式: 绘制可拖拽手柄
    final handlePaint = Paint()
      ..color = draggable ? Colors.red.withValues(alpha: 0.9) : Colors.grey.withValues(alpha: 0.0)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.fill;

    // 水平线
    for (int i = 0; i < hLines.length; i++) {
      final y = hLines[i] * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), i == draggingH ? activePaint : linePaint);
      if (draggable) {
        canvas.drawCircle(Offset(w / 2, y), 6, i == draggingH ? activePaint : handlePaint);
      }
    }

    // 垂直线
    for (int i = 0; i < vLines.length; i++) {
      final x = vLines[i] * w;
      canvas.drawLine(Offset(x, 0), Offset(x, h), i == draggingV ? activePaint : linePaint);
      if (draggable) {
        canvas.drawCircle(Offset(x, h / 2), 6, i == draggingV ? activePaint : handlePaint);
      }
    }

    // 边框
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant SplitLinePainter old) {
    if (old.rows != rows || old.cols != cols) return true;
    if (old.draggable != draggable) return true;
    if (old.draggingH != draggingH || old.draggingV != draggingV) return true;
    if (!_listEquals(old.hLines, hLines)) return true;
    if (!_listEquals(old.vLines, vLines)) return true;
    return false;
  }

  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.0001) return false;
    }
    return true;
  }
}
