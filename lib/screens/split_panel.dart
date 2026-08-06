// 分割配置面板 (SRS 4.2 模块2/3)
// 快速配置(全局等分) + 独立微调(单张拖拽)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../models/split_config.dart';
import '../state/file_list_state.dart';
import '../state/split_state.dart';
import '../widgets/split_canvas.dart';

class SplitPanel extends StatelessWidget {
  const SplitPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FileListState, SplitState>(
      builder: (context, fileList, split, _) {
        if (fileList.count == 0) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_not_supported, size: 56),
                const SizedBox(height: 12),
                Text('请先在「导入」页添加文件', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          );
        }
        split.syncConfigs(fileList.files);
        final activeFile = _activeFile(fileList, split);
        final config = activeFile != null ? split.getConfig(activeFile.id) : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            if (isWide) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 320,
                      child: _buildConfigPanel(context, split, activeFile, config),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildPreview(context, fileList, split, activeFile, config)),
                  ],
                ),
              );
            }
            // 窄屏: 配置在上, 预览在下
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  SizedBox(
                    height: 340,
                    child: _buildConfigPanel(context, split, activeFile, config),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildPreview(context, fileList, split, activeFile, config)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 配置面板 (左/上): 快速配置 + 预设 + 模式选择 + 文件信息
  Widget _buildConfigPanel(BuildContext context, SplitState split, FileItem? activeFile, SplitConfig? config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildQuickConfig(context, split),
          const SizedBox(height: 12),
          _buildPresets(context, split),
          const SizedBox(height: 12),
          _buildModeSelector(context, split),
          const SizedBox(height: 12),
          if (activeFile != null && config != null) ...[
            _buildFileInfo(context, activeFile, config),
          ],
        ],
      ),
    );
  }

  FileItem? _activeFile(FileListState fileList, SplitState split) {
    if (split.activeFileId == null) return fileList.files.first;
    final f = fileList.files.where((f) => f.id == split.activeFileId!).firstOrNull;
    return f ?? fileList.files.first;
  }

  /// 快速配置 (SRS 4.2.1: 横向/纵向分割份数, 全局应用)
  Widget _buildQuickConfig(BuildContext context, SplitState split) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('快速配置 (全局等分)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: '横向份数 (行)',
                    value: split.currentRows,
                    onChanged: (v) => split.setQuickGrid(v, split.currentCols),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    label: '纵向份数 (列)',
                    value: split.currentCols,
                    onChanged: (v) => split.setQuickGrid(split.currentRows, v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('共 ${split.currentRows * split.currentCols} 块', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  /// 预设列表 (SRS 4.2.1: 内置 + 自定义)
  Widget _buildPresets(BuildContext context, SplitState split) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('预设', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '新增自定义预设',
                  onPressed: () => _showAddPresetDialog(context, split),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: split.presets.map((p) {
                final selected = p.rows == split.currentRows && p.cols == split.currentCols;
                return InputChip(
                  label: Text('${p.label} (${p.rows}×${p.cols})'),
                  selected: selected,
                  onSelected: (_) => split.setQuickGrid(p.rows, p.cols),
                  onDeleted: p.isBuiltIn ? null : () => split.removePreset(p.id),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 分割模式选择 (两种业务流程)
  Widget _buildModeSelector(BuildContext context, SplitState split) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('业务流程', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<SplitMode>(
              segments: const [
                ButtonSegment(value: SplitMode.quick, label: Text('快速等分'), icon: Icon(Icons.flash_on)),
                ButtonSegment(value: SplitMode.soloTune, label: Text('独立微调'), icon: Icon(Icons.edit)),
              ],
              selected: {split.mode},
              onSelectionChanged: (s) => split.setMode(s.first),
            ),
            const SizedBox(height: 8),
            Text(
              switch (split.mode) {
                SplitMode.quick => '全部图片统一等分分割 (行列数相同)',
                SplitMode.soloTune => '逐张图片独立微调, 适配不同尺寸 (拖拽调整分割线)',
              },
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// 当前文件信息
  Widget _buildFileInfo(BuildContext context, FileItem file, SplitConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前微调文件', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${config.rows}×${config.cols} = ${config.totalSlices} 块', style: Theme.of(context).textTheme.bodySmall),
            if (file.imageWidth != null) Text('尺寸: ${file.imageWidth}×${file.imageHeight}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  /// 预览画布 (SRS 4.3 模块3: 预览画布交互)
  Widget _buildPreview(
    BuildContext context,
    FileListState fileList,
    SplitState split,
    FileItem? activeFile,
    SplitConfig? config,
  ) {
    if (activeFile == null || config == null) {
      return const Center(child: Text('无可用预览'));
    }

    return Column(
      children: [
        // 文件选择器 (切换微调对象)
        Padding(
          padding: const EdgeInsets.all(8),
          child: DropdownButton<String>(
            value: activeFile.id,
            isExpanded: true,
            items: fileList.files
                .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (id) => split.setActiveFile(id),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SplitCanvas(
                file: activeFile,
                config: config,
                enabled: split.mode == SplitMode.soloTune,
                onHLineChanged: (i, v) => split.setHLine(activeFile.id, i, v),
                onVLineChanged: (i, v) => split.setVLine(activeFile.id, i, v),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddPresetDialog(BuildContext context, SplitState split) {
    final nameCtrl = TextEditingController();
    var rows = 2;
    var cols = 2;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('新增自定义预设'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '预设名称')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _NumberField(label: '行', value: rows, onChanged: (v) => setSt(() => rows = v))),
                  const SizedBox(width: 8),
                  Expanded(child: _NumberField(label: '列', value: cols, onChanged: (v) => setSt(() => cols = v))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                split.addPreset(name, rows, cols);
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 数字输入字段 - 完整功能: 标签、输入框、上下调节按钮
/// 布局: 标签在上, 输入框+按钮在下, 确保输入框有足够宽度
class _NumberField extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != int.tryParse(_controller.text)) {
      _controller.value = TextEditingValue(
        text: widget.value.toString(),
        selection: TextSelection.collapsed(offset: widget.value.toString().length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setValue(int newValue) {
    final clamped = newValue.clamp(widget.min, widget.max);
    _controller.value = TextEditingValue(
      text: clamped.toString(),
      selection: TextSelection.collapsed(offset: clamped.toString().length),
    );
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (s) {
                  final v = int.tryParse(s);
                  if (v != null && v >= widget.min && v <= widget.max) {
                    widget.onChanged(v);
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 48,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.value < widget.max ? () => _setValue(widget.value + 1) : null,
                      child: Icon(Icons.arrow_drop_up, size: 20,
                          color: widget.value < widget.max ? null : Theme.of(context).disabledColor),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: widget.value > widget.min ? () => _setValue(widget.value - 1) : null,
                      child: Icon(Icons.arrow_drop_down, size: 20,
                          color: widget.value > widget.min ? null : Theme.of(context).disabledColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
