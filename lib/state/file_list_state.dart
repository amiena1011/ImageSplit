// 文件列表状态 (SRS 4.1 模块1: 文件上传&文件列表管理)
// 双视图切换、列表管理、排序、退出保存逻辑

import 'package:flutter/foundation.dart';
import '../models/file_item.dart';
import '../services/config_service.dart';
import '../services/file_service.dart';
import '../services/log_service.dart';

enum FileViewMode { grid, list }

class FileListState extends ChangeNotifier {
  final FileService _fileService;
  final ConfigService _configService;
  final LogService _logService;

  FileListState(this._fileService, this._configService, this._logService);

  final List<FileItem> _files = [];
  final Set<String> _selectedIds = {};
  FileViewMode _viewMode = FileViewMode.grid;
  bool _keepFileList = false;

  List<FileItem> get files => List.unmodifiable(_files);
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  FileViewMode get viewMode => _viewMode;
  bool get keepFileList => _keepFileList;
  int get count => _files.length;

  /// 通过文件选择器导入 (SRS 4.1.2)
  Future<int> pickAndAdd() async {
    final items = await _fileService.pickFiles();
    return _addItems(items);
  }

  /// 通过路径导入 (Windows 拖拽 SRS 4.1.2)
  Future<int> addFromPaths(List<String> paths) async {
    final items = await _fileService.fromPaths(paths);
    return _addItems(items);
  }

  /// 添加多个文件项 (用于PDF转换后的文件)
  void addAll(List<FileItem> items) {
    if (items.isEmpty) return;
    _files.addAll(items);
    _logService.success('PDF转换添加 ${items.length} 个文件');
    notifyListeners();
    // 异步校验
    _validateItems(items);
  }

  int _addItems(List<FileItem> items) {
    if (items.isEmpty) return 0;
    _files.addAll(items);
    _logService.success('导入 ${items.length} 个文件');
    notifyListeners();
    // 异步校验 (SRS 4.1.4 导入预校验)
    _validateItems(items);
    return items.length;
  }

  Future<void> _validateItems(List<FileItem> items) async {
    for (final item in items) {
      item.status = FileItemStatus.loading;
      notifyListeners();
      final ok = await _fileService.validateFile(item);
      item.status = ok ? FileItemStatus.ready : FileItemStatus.error;
      if (!ok) _logService.error('文件校验失败: ${item.name}', detail: item.errorMessage);
      notifyListeners();
    }
  }

  /// 选中/取消选中 (SRS 4.1.4 单条、多条文件选中)
  void toggleSelect(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(_files.map((f) => f.id));
    notifyListeners();
  }

  void selectNone() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// 删除选中项 (SRS 4.1.4)
  void removeSelected() {
    final count = _selectedIds.length;
    _files.removeWhere((f) => _selectedIds.contains(f.id));
    _selectedIds.clear();
    _logService.info('删除 $count 个文件');
    notifyListeners();
  }

  /// 一键清空 (SRS 4.1.4)
  void clearAll() {
    final count = _files.length;
    _files.clear();
    _selectedIds.clear();
    _logService.info('清空全部 $count 个文件');
    notifyListeners();
  }

  /// 设置视图模式 (SRS 4.1.3 双视图切换)
  void setViewMode(FileViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  // ---------- 排序 (SRS 4.1.4: 排序顺序决定输出顺序) ----------

  /// 键盘方向键上移 (Windows SRS 2)
  void moveUp(String id) {
    final i = _files.indexWhere((f) => f.id == id);
    if (i > 0) {
      final tmp = _files[i];
      _files[i] = _files[i - 1];
      _files[i - 1] = tmp;
      notifyListeners();
    }
  }

  /// 键盘方向键下移 (Windows SRS 2)
  void moveDown(String id) {
    final i = _files.indexWhere((f) => f.id == id);
    if (i >= 0 && i < _files.length - 1) {
      final tmp = _files[i];
      _files[i] = _files[i + 1];
      _files[i + 1] = tmp;
      notifyListeners();
    }
  }

  /// 长按拖拽重排序 (Android SRS 2)
  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _files.removeAt(oldIndex);
    _files.insert(newIndex, item);
    notifyListeners();
  }

  /// 获取排序后的文件 (输出顺序)
  List<FileItem> get orderedFiles => List.unmodifiable(_files);

  // ---------- 退出保存逻辑 (SRS 4.1.5) ----------

  Future<void> setKeepFileList(bool keep) async {
    _keepFileList = keep;
    await _configService.setKeepFileList(keep);
    notifyListeners();
  }

  /// 保存当前文件列表 (SRS 4.1.5: 选「是」保存, 下次启动恢复)
  Future<void> saveFileList() async {
    final json = _files.map((f) => f.toJson()).toList();
    await _configService.setSavedFileList(json);
    _logService.info('文件列表已保存 (${_files.length} 项)');
  }

  /// 恢复文件列表 (SRS 4.1.5: 下次启动自动恢复)
  Future<int> restoreFileList() async {
    final saved = await _configService.getSavedFileList();
    if (saved.isEmpty) return 0;
    final items = <FileItem>[];
    for (final json in saved) {
      try {
        final item = FileItem.fromJson(json);
        // 校验文件仍存在
        final ok = await _fileService.validateFile(item);
        if (ok) {
          item.status = FileItemStatus.ready;
          items.add(item);
        }
      } catch (_) {}
    }
    _files.addAll(items);
    _keepFileList = await _configService.getKeepFileList();
    if (items.isNotEmpty) {
      _logService.info('恢复上次文件列表: ${items.length} 项');
    }
    notifyListeners();
    return items.length;
  }

  /// 清除保存的文件列表 (SRS 4.1.5: 选「否」清空退出)
  Future<void> clearSavedFileList() async {
    await _configService.clearSavedFileList();
    _logService.info('已清除保存的文件列表');
  }
}
