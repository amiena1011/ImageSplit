// 图像分割服务 (SRS 4.2/4.3 模块2/3/4)
// 性能约束 (SRS 7.1): 超大TIFF必须FFI+Isolate子线程处理, 杜绝主线程卡顿
// 使用 image 包解码, Isolate 隔离耗时任务
// 原始文件只读 (SRS 7.2): 仅读取源文件, 切片写入独立输出目录

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/file_item.dart';
import '../models/split_config.dart';

/// 单个切片结果
class SliceResult {
  final int index;
  final String sourceName;
  final Uint8List bytes;
  final int width;
  final int height;
  final String format;

  SliceResult({
    required this.index,
    required this.sourceName,
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
  });
}

/// 分割任务参数 (传递到 Isolate, 必须为静态/基本类型)
class _SplitTaskInput {
  final String path;
  final int rows;
  final int cols;
  final List<double> hLines;
  final List<double> vLines;
  final String format; // png/jpg/bmp/tiff
  final int quality;
  final String sourceName;
  final SendPort sendPort;

  _SplitTaskInput({
    required this.path,
    required this.rows,
    required this.cols,
    required this.hLines,
    required this.vLines,
    required this.format,
    required this.quality,
    required this.sourceName,
    required this.sendPort,
  });
}

class ImageSplitService {
  /// 分割单张图片, 通过 Isolate 执行 (SRS 7.1)
  ///
  /// [onProgress] 进度回调 0.0~1.0
  Stream<SliceResult> splitImage({
    required FileItem file,
    required SplitConfig config,
    required String format,
    required int quality,
  }) async* {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _splitIsolateEntry,
      _SplitTaskInput(
        path: file.path,
        rows: config.rows,
        cols: config.cols,
        hLines: List<double>.from(config.hLines),
        vLines: List<double>.from(config.vLines),
        format: format,
        quality: quality,
        sourceName: file.name,
        sendPort: receivePort.sendPort,
      ),
    );

    await for (final msg in receivePort) {
      if (msg == null) {
        receivePort.close();
        break;
      }
      if (msg is Map && msg['error'] != null) {
        receivePort.close();
        throw Exception(msg['error'] as String);
      }
      if (msg is Map && msg['done'] == true) {
        receivePort.close();
        break;
      }
      if (msg is Map && msg['result'] != null) {
        final r = msg['result'] as Map;
        yield SliceResult(
          index: r['index'] as int,
          sourceName: r['sourceName'] as String,
          bytes: r['bytes'] as Uint8List,
          width: r['width'] as int,
          height: r['height'] as int,
          format: r['format'] as String,
        );
      }
    }
  }

  /// Isolate 入口 (顶级函数)
  static void _splitIsolateEntry(_SplitTaskInput input) {
    final receivePort = ReceivePort();
    input.sendPort.send(receivePort.sendPort);

    try {
      final bytes = File(input.path).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        input.sendPort.send({'error': '无法解码图片: ${input.sourceName}'});
        return;
      }

      final w = decoded.width;
      final h = decoded.height;
      final hBounds = <double>[0.0, ...input.hLines, 1.0];
      final vBounds = <double>[0.0, ...input.vLines, 1.0];

      for (int row = 0; row < input.rows; row++) {
        for (int col = 0; col < input.cols; col++) {
          // 排序 (SRS 4.3.4): 先行后列
          final index = row * input.cols + col;
          final x0 = (vBounds[col] * w).round();
          final y0 = (hBounds[row] * h).round();
          final x1 = (vBounds[col + 1] * w).round();
          final y1 = (hBounds[row + 1] * h).round();
          final sw = x1 - x0;
          final sh = y1 - y0;

          final cropped = img.copyCrop(decoded, x: x0, y: y0, width: sw, height: sh);
          final outBytes = _encode(cropped, input.format, input.quality);

          input.sendPort.send({
            'result': {
              'index': index,
              'sourceName': input.sourceName,
              'bytes': Uint8List.fromList(outBytes),
              'width': sw,
              'height': sh,
              'format': input.format,
            }
          });
        }
      }
      input.sendPort.send({'done': true});
    } catch (e) {
      input.sendPort.send({'error': '分割失败: $e'});
    }
  }

  /// 编码切片
  static List<int> _encode(img.Image image, String format, int quality) {
    switch (format.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return img.encodeJpg(image, quality: quality);
      case 'bmp':
        return img.encodeBmp(image);
      case 'tiff':
      case 'tif':
        // SRS 4.3.3: TIFF 固定无损输出
        return img.encodeTiff(image);
      case 'png':
      default:
        return img.encodePng(image, level: _pngLevel(quality));
    }
  }

  static int _pngLevel(int quality) {
    // quality 越高, 压缩级别越低 (0=无压缩, 9=最大压缩)
    return (9 - (quality / 100 * 9)).round().clamp(0, 9);
  }

  /// 读取图片尺寸 (用于预览, 较快)
  static Future<({int width, int height})> readDimensions(String path) async {
    final r = await compute(_readDimensionsIsolate, path);
    return (width: r.$1, height: r.$2);
  }

  static (int, int) _readDimensionsIsolate(String path) {
    final bytes = File(path).readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return (0, 0);
    return (decoded.width, decoded.height);
  }
}
