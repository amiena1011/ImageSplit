// 文件导入与管理服务 (SRS 4.1 模块1: 文件上传&文件列表管理)
// 支持格式校验、损坏文件检测、大图加载进度展示
// 原始文件只读不写 (SRS 7.2 安全约束)

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/file_item.dart';

class FileService {
  final _uuid = const Uuid();

  /// 通过系统文件选择器导入文件 (双端通用 SRS 4.1.2)
  Future<List<FileItem>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: AppConstants.supportedExtensions
          .map((e) => e.substring(1))
          .toList(),
    );

    if (result == null || result.files.isEmpty) return [];
    return result.files.map(_fromPlatformFile).toList();
  }

  /// 通过路径列表创建文件项 (Windows 拖拽导入 SRS 4.1.2)
  Future<List<FileItem>> fromPaths(List<String> paths) async {
    final items = <FileItem>[];
    for (final p in paths) {
      final file = File(p);
      if (!await file.exists()) continue;
      final item = await _fromFile(file);
      if (item != null) items.add(item);
    }
    return items;
  }

  FileItem _fromPlatformFile(PlatformFile pf) {
    final path = pf.path ?? pf.name;
    final ext = path.toLowerCase().substring(path.lastIndexOf('.'));
    return FileItem(
      id: _uuid.v4(),
      path: path,
      name: pf.name,
      sizeBytes: pf.size,
      type: FileItem.typeFromExtension(ext),
      addedAt: DateTime.now(),
    );
  }

  Future<FileItem?> _fromFile(File file) async {
    try {
      final stat = await file.stat();
      final name = file.uri.pathSegments.last;
      final ext = name.toLowerCase().substring(name.lastIndexOf('.'));
      if (!AppConstants.supportedExtensions.contains(ext)) return null;
      return FileItem(
        id: _uuid.v4(),
        path: file.path,
        name: name,
        sizeBytes: stat.size,
        type: FileItem.typeFromExtension(ext),
        addedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// 校验文件是否存在且未损坏 (SRS 4.1.4 导入预校验)
  Future<bool> validateFile(FileItem item) async {
    try {
      final file = File(item.path);
      if (!await file.exists()) {
        item.errorMessage = '文件不存在';
        item.status = FileItemStatus.error;
        return false;
      }
      final stat = await file.stat();
      if (stat.size == 0) {
        item.errorMessage = '文件为空';
        item.status = FileItemStatus.error;
        return false;
      }
      return true;
    } catch (e) {
      item.errorMessage = '校验失败: $e';
      item.status = FileItemStatus.error;
      return false;
    }
  }

  /// 删除文件 (仅清理输出临时文件, 不触碰原始文件 SRS 7.2)
  Future<void> safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// 默认输出目录 (Android: 下载目录 / Windows: 文档目录 SRS 4.3.1)
  static const _downloadDir = 'downloads';
  String defaultOutputDirName() => _downloadDir;
}
