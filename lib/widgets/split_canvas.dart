// 预览画布交互组件 (SRS 4.3 模块3: 预览画布交互模块)
// 优化: 使用 ListenableBuilder 监听 SplitConfig 变化, 避免整个 widget tree 重建
// 双端差异化: 鼠标拖拽 / 手指触屏拖拽调整分割线 (SRS 2)
// 实时预览分割效果

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../models/split_config.dart';
import 'split_line_painter.dart';

class SplitCanvas extends StatefulWidget {
  final FileItem? file;
  final SplitConfig config;
  final bool enabled;
  final void Function(int lineIndex, double normalized)? onHLineChanged;
  final void Function(int lineIndex, double normalized)? onVLineChanged;

  const SplitCanvas({
    super.key,
    required this.file,
    required this.config,
    this.enabled = true,
    this.onHLineChanged,
    this.onVLineChanged,
  });

  @override
  State<SplitCanvas> createState() => _SplitCanvasState();
}

class _SplitCanvasState extends State<SplitCanvas> {
  int? _draggingH;
  int? _draggingV;
  Size _canvasSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _computeCanvasSize(constraints);
        _canvasSize = size;
        return ClipRect(
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              // 图片背景
              SizedBox(
                width: size.width,
                height: size.height,
                child: _buildBackground(),
              ),
              // 分割线层 - 使用 ListenableBuilder 监听 SplitConfig 变化
              ListenableBuilder(
                listenable: widget.config,
                builder: (context, child) => Positioned(
                  left: 0,
                  top: 0,
                  width: size.width,
                  height: size.height,
                  child: GestureDetector(
                    onPanStart: widget.enabled ? _onPanStart : null,
                    onPanUpdate: widget.enabled ? _onPanUpdate : null,
                    onPanEnd: widget.enabled ? _onPanEnd : null,
                    behavior: widget.enabled ? HitTestBehavior.opaque : HitTestBehavior.translucent,
                    child: CustomPaint(
                      size: size,
                      painter: SplitLinePainter(
                        rows: widget.config.rows,
                        cols: widget.config.cols,
                        hLines: List<double>.from(widget.config.hLines),
                        vLines: List<double>.from(widget.config.vLines),
                        draggingH: _draggingH,
                        draggingV: _draggingV,
                        draggable: widget.enabled,
                      ),
                    ),
                  ),
                ),
              ),
              // 快速模式提示
              if (!widget.enabled)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 14, color: Colors.white70),
                        SizedBox(width: 4),
                        Text('快速等分模式 · 切换到独立微调可拖拽分割线',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    if (widget.file == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Text('请选择文件以预览')),
      );
    }
    return Image.file(
      File(widget.file!.path),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey,
        child: const Center(child: Icon(Icons.broken_image, size: 48)),
      ),
    );
  }

  Size _computeCanvasSize(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    if (widget.file?.imageWidth != null && widget.file?.imageHeight != null) {
      final ratio = widget.file!.imageWidth! / widget.file!.imageHeight!;
      if (w / h > ratio) {
        return Size(h * ratio, h);
      } else {
        return Size(w, w / ratio);
      }
    }
    return Size(w, h);
  }

  void _onPanStart(DragStartDetails d) {
    final hit = _hitTest(d.localPosition);
    if (hit != null) {
      setState(() {
        if (hit.$1 == 'h') {
          _draggingH = hit.$2;
        } else {
          _draggingV = hit.$2;
        }
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final local = d.localPosition;
    if (_draggingH != null && _canvasSize.height > 0) {
      final norm = (local.dy / _canvasSize.height).clamp(0.02, 0.98);
      widget.onHLineChanged?.call(_draggingH!, norm);
    } else if (_draggingV != null && _canvasSize.width > 0) {
      final norm = (local.dx / _canvasSize.width).clamp(0.02, 0.98);
      widget.onVLineChanged?.call(_draggingV!, norm);
    }
  }

  void _onPanEnd(_) {
    setState(() {
      _draggingH = null;
      _draggingV = null;
    });
  }

  (String, int)? _hitTest(Offset local) {
    const threshold = 12.0;
    for (var i = 0; i < widget.config.hLines.length; i++) {
      final y = widget.config.hLines[i] * _canvasSize.height;
      if ((local.dy - y).abs() < threshold) {
        return ('h', i);
      }
    }
    for (var i = 0; i < widget.config.vLines.length; i++) {
      final x = widget.config.vLines[i] * _canvasSize.width;
      if ((local.dx - x).abs() < threshold) {
        return ('v', i);
      }
    }
    return null;
  }
}
