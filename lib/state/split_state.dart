// 分割配置状态 (SRS 4.2 模块2/3: 分割预览与参数配置)
// 快速配置 + 手动微调, 三种业务流程

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/file_item.dart';
import '../models/split_config.dart';
import '../models/split_preset.dart';
import '../services/config_service.dart';
import '../services/log_service.dart';

class SplitState extends ChangeNotifier {
  final ConfigService _configService;
  final LogService _logService;

  SplitState(this._configService, this._logService);

  final _uuid = const Uuid();

  // 当前选择的快速配置参数 (全局等分基准 SRS 4.2.1)
  int _currentRows = 1;
  int _currentCols = 2;

  // 预设列表
  final List<SplitPreset> _presets = [];

  // 每个文件的分割配置 (SRS 4.2.2 手动微调)
  final Map<String, SplitConfig> _configs = {};

  // 当前选中的文件 (用于微调)
  String? _activeFileId;

  // 分割模式 (SRS 4.2.3)
  SplitMode _mode = SplitMode.quick;

  int get currentRows => _currentRows;
  int get currentCols => _currentCols;
  List<SplitPreset> get presets => List.unmodifiable(_presets);
  SplitMode get mode => _mode;
  String? get activeFileId => _activeFileId;

  /// 初始化: 加载内置 + 自定义预设 (SRS 4.2.1)
  Future<void> init() async {
    _presets.addAll(
      AppConstants.builtInPresets.map(
        (b) => SplitPreset(
          id: 'builtin_${b.name}',
          name: b.name,
          rows: b.rows,
          cols: b.cols,
          isBuiltIn: true,
        ),
      ),
    );
    final custom = await _configService.getCustomPresets();
    _presets.addAll(custom);
    notifyListeners();
  }

  /// 设置当前快速配置 (SRS 4.2.1 全局应用至全部图片)
  void setQuickGrid(int rows, int cols) {
    _currentRows = rows;
    _currentCols = cols;
    _mode = SplitMode.quick;
    // 全局应用至全部已配置文件
    for (final cfg in _configs.values) {
      cfg.setGrid(rows, cols);
    }
    _logService.info('快速配置: $rows×$cols, 已应用至全部图片');
    notifyListeners();
  }

  /// 为文件初始化配置 (导入时调用)
  void ensureConfig(FileItem file) {
    if (!_configs.containsKey(file.id)) {
      _configs[file.id] = SplitConfig(
        fileId: file.id,
        rows: _currentRows,
        cols: _currentCols,
      );
    }
  }

  /// 获取文件分割配置
  SplitConfig? getConfig(String fileId) => _configs[fileId];

  /// 批量初始化配置 (仅对新文件创建配置, 不触发重建)
  void syncConfigs(List<FileItem> files) {
    bool changed = false;
    for (final f in files) {
      if (!_configs.containsKey(f.id)) {
        _configs[f.id] = SplitConfig(
          fileId: f.id,
          rows: _currentRows,
          cols: _currentCols,
        );
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// 设置当前微调文件 (SRS 4.2.2)
  void setActiveFile(String? fileId) {
    _activeFileId = fileId;
    if (fileId != null && _mode == SplitMode.quick) {
      _mode = SplitMode.soloTune;
    }
    notifyListeners();
  }

  /// 切换分割模式
  /// - 切换到 quick: 重置所有配置为快速等分 (丢弃之前的微调)
  /// - 切换到 soloTune: 保留当前配置, 允许独立微调
  void setMode(SplitMode mode) {
    _mode = mode;
    if (mode == SplitMode.quick) {
      // 切换到快速模式: 将快速配置应用到所有文件, 丢弃微调
      for (final cfg in _configs.values) {
        cfg.setGrid(_currentRows, _currentCols);
      }
      _logService.info('切换到快速等分模式: $_currentRows×$_currentCols, 已重置全部图片');
    } else {
      _logService.info('切换到独立微调模式');
    }
    notifyListeners();
  }

  /// 单张微调: 设置水平分割线 (SRS 4.2.2)
  /// 注意: 不再调用 SplitState.notifyListeners, 避免整个 widget tree 重建
  /// SplitConfig 自身会 notifyListeners, SplitCanvas 通过 ListenableBuilder 直接监听
  void setHLine(String fileId, int index, double value) {
    _configs[fileId]?.setHLine(index, value);
  }

  /// 单张微调: 设置垂直分割线
  void setVLine(String fileId, int index, double value) {
    _configs[fileId]?.setVLine(index, value);
  }

  // ---------- 预设管理 (SRS 4.2.1 自定义预设增删) ----------

  /// 新增自定义预设
  Future<void> addPreset(String name, int rows, int cols) async {
    final preset = SplitPreset(
      id: _uuid.v4(),
      name: name,
      rows: rows,
      cols: cols,
      isBuiltIn: false,
    );
    _presets.add(preset);
    await _configService.setCustomPresets(_presets.where((p) => !p.isBuiltIn).toList());
    _logService.success('新增预设: $name ($rows×$cols)');
    notifyListeners();
  }

  /// 删除自定义预设 (内置不可删 SRS 4.2.1)
  Future<void> removePreset(String id) async {
    final preset = _presets.firstWhere((p) => p.id == id);
    if (preset.isBuiltIn) {
      _logService.warning('内置预设不可删除');
      return;
    }
    _presets.removeWhere((p) => p.id == id);
    await _configService.setCustomPresets(_presets.where((p) => !p.isBuiltIn).toList());
    _logService.info('删除预设: ${preset.name}');
    notifyListeners();
  }

  /// 移除已删除文件的配置
  void removeConfig(String fileId) {
    _configs.remove(fileId);
    if (_activeFileId == fileId) _activeFileId = null;
    notifyListeners();
  }

  /// 获取全部配置 (供导出使用)
  Map<String, SplitConfig> get allConfigs => Map.unmodifiable(_configs);
}
