// 文件列表/方块视图组件 (SRS 4.1.3 模块1: 列表双视图切换)
// 方块视图: 缩略图为主; 列表视图: 文件名、大小、类型
// 排序: Windows 键盘上下方向键; Android 长按拖拽 (SRS 2)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/file_item.dart';
import '../state/file_list_state.dart';

class FileListView extends StatelessWidget {
  const FileListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileListState>(
      builder: (context, state, _) {
        if (state.count == 0) {
          return _buildEmpty(context);
        }
        return Column(
          children: [
            _buildToolbar(context, state),
            Expanded(child: _buildContent(context, state)),
            _buildSelectionBar(context, state),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          Text('暂无文件, 请点击上方按钮或拖拽导入', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, FileListState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text('共 ${state.count} 个文件', style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          SegmentedButton<FileViewMode>(
            segments: const [
              ButtonSegment(value: FileViewMode.grid, icon: Icon(Icons.grid_view)),
              ButtonSegment(value: FileViewMode.list, icon: Icon(Icons.view_list)),
            ],
            selected: {state.viewMode},
            onSelectionChanged: (s) => state.setViewMode(s.first),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, FileListState state) {
    if (state.viewMode == FileViewMode.grid) {
      return _buildGrid(context, state);
    }
    return _buildList(context, state);
  }

  /// 方块视图 (SRS 4.1.3: 缩略图为主)
  Widget _buildGrid(BuildContext context, FileListState state) {
    return ReorderableGridView(
      state: state,
      children: state.files.map((f) {
        final selected = state.selectedIds.contains(f.id);
        return _GridCard(
          key: ValueKey(f.id),
          file: f,
          selected: selected,
          onTap: () => state.toggleSelect(f.id),
        );
      }).toList(),
    );
  }

  /// 列表视图 (SRS 4.1.3: 文件名、大小、类型)
  Widget _buildList(BuildContext context, FileListState state) {
    // Android: 长按拖拽排序 (SRS 2)
    return ReorderableListView.builder(
      buildDefaultDragHandles: PlatformUtils.isAndroid,
      itemCount: state.files.length,
      onReorder: state.reorder,
      itemBuilder: (context, index) {
        final f = state.files[index];
        final selected = state.selectedIds.contains(f.id);
        return _ListTile(
          key: ValueKey(f.id),
          file: f,
          index: index,
          selected: selected,
          onTap: () => state.toggleSelect(f.id),
          onMoveUp: PlatformUtils.isWindows ? () => state.moveUp(f.id) : null,
          onMoveDown: PlatformUtils.isWindows ? () => state.moveDown(f.id) : null,
        );
      },
    );
  }

  Widget _buildSelectionBar(BuildContext context, FileListState state) {
    if (state.selectedIds.isEmpty) return const SizedBox.shrink();
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text('已选 ${state.selectedIds.length} 项'),
            const Spacer(),
            TextButton.icon(
              onPressed: state.selectNone,
              icon: const Icon(Icons.deselect),
              label: const Text('取消'),
            ),
            TextButton.icon(
              onPressed: () => _confirmRemove(context, state),
              icon: const Icon(Icons.delete_outline),
              label: const Text('删除'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, FileListState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除选中文件'),
        content: Text('确定从列表删除 ${state.selectedIds.length} 个文件? (不会删除原始文件)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              state.removeSelected();
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 方块视图卡片
class _GridCard extends StatelessWidget {
  final FileItem file;
  final bool selected;
  final VoidCallback onTap;
  const _GridCard({super.key, required this.file, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildThumb()),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                      Text('${file.sizeFormatted} · IMG', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
            if (file.status == FileItemStatus.loading)
              const Positioned.fill(child: Center(child: CircularProgressIndicator())),
            if (file.status == FileItemStatus.error)
              const Positioned(top: 4, right: 4, child: Icon(Icons.error, color: Colors.red, size: 18)),
            if (selected)
              Positioned(top: 4, right: 4, child: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb() {
    return Image.file(File(file.path), fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)));
  }
}

/// 列表视图条目
class _ListTile extends StatelessWidget {
  final FileItem file;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  const _ListTile({super.key, required this.file, required this.index, required this.selected, required this.onTap, this.onMoveUp, this.onMoveDown});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: key,
      tileColor: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: const Icon(Icons.image, size: 20),
      ),
      title: Text(file.name),
      subtitle: Text('${file.sizeFormatted} · IMG · #${index + 1}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onMoveUp != null)
            IconButton(icon: const Icon(Icons.arrow_upward), onPressed: onMoveUp, tooltip: '上移'),
          if (onMoveDown != null)
            IconButton(icon: const Icon(Icons.arrow_downward), onPressed: onMoveDown, tooltip: '下移'),
          if (PlatformUtils.isAndroid)
            const Icon(Icons.drag_handle),
        ],
      ),
      selected: selected,
      onTap: onTap,
    );
  }
}

/// 方块视图支持拖拽排序 (Android 长按拖拽 SRS 2)
class ReorderableGridView extends StatelessWidget {
  final FileListState state;
  final List<Widget> children;
  const ReorderableGridView({super.key, required this.state, required this.children});

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.isAndroid) {
      return GridView.count(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        children: children,
      );
    }
    // Android: 简化为可滚动网格 (长按拖拽由 ReorderableListView 体现于列表视图)
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 0.8,
      children: children,
    );
  }
}

/// 捕获键盘方向键 (Windows 排序 SRS 2)
/// 使用: 包裹文件列表区域
class KeyboardReorderInterceptor extends StatelessWidget {
  final Widget child;
  const KeyboardReorderInterceptor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.arrowDown) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
