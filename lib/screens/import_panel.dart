// 导入面板 (SRS 4.1 模块1: 文件上传&文件列表管理)
// Windows: 点击选择 + 拖拽批量上传 (desktop_drop)
// Android: 系统文件选择器多选

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../state/file_list_state.dart';
import '../state/split_state.dart';
import '../widgets/file_list_view.dart';

class ImportPanel extends StatefulWidget {
  const ImportPanel({super.key});

  @override
  State<ImportPanel> createState() => _ImportPanelState();
}

class _ImportPanelState extends State<ImportPanel> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActions(context),
          const SizedBox(height: 12),
          Expanded(child: _buildDropArea(context)),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final fileList = context.read<FileListState>();
    return Wrap(
      spacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () async {
            final n = await fileList.pickAndAdd();
            if (n > 0 && context.mounted) {
              context.read<SplitState>().syncConfigs(fileList.files);
            }
          },
          icon: const Icon(Icons.folder_open),
          label: const Text('选择文件'),
        ),
        OutlinedButton.icon(
          onPressed: fileList.count == 0
              ? null
              : () => _confirmClear(context, fileList),
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('清空列表'),
        ),
        const SizedBox(width: 8),
        Chip(
          avatar: const Icon(Icons.filter_alt, size: 16),
          label: Text('支持: ${AppConstants.supportedExtensions.join(' ')}'),
        ),
      ],
    );
  }

  Widget _buildDropArea(BuildContext context) {
    final child = const FileListView();

    // Windows: 拖拽批量上传 (SRS 4.1.2)
    if (!PlatformUtils.isWindows) {
      return child;
    }
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (detail) async {
        setState(() => _dragging = false);
        final paths = detail.files.map((f) => f.path).toList();
        final fileList = context.read<FileListState>();
        final n = await fileList.addFromPaths(paths);
        if (n > 0 && context.mounted) {
          context.read<SplitState>().syncConfigs(fileList.files);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (_dragging)
            IgnorePointer(
              child: Container(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                child: Center(
                  child: Icon(Icons.file_download, size: 64, color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, FileListState fileList) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空全部文件'),
        content: const Text('确定清空全部文件列表? (不会删除原始文件)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              fileList.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}
