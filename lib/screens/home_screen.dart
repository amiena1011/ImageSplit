// 主界面骨架 (SRS 模块7: Material3 UI 主题系统)
// 桌面端 NavigationRail / 移动端 BottomNavigationBar
// 三个主面板: 导入、分割、导出 + 主题切换 + 退出保存

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../state/app_state.dart';
import '../state/file_list_state.dart';
import '../state/split_state.dart';
import '../widgets/progress_panel.dart';
import '../widgets/log_panel.dart';
import 'import_panel.dart';
import 'split_panel.dart';
import 'export_panel.dart';

enum NavSection { import, split, export }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NavSection _section = NavSection.import;

  @override
  void initState() {
    super.initState();
    // 初始化恢复文件列表 (SRS 4.1.5)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fileList = context.read<FileListState>();
      final split = context.read<SplitState>();
      await split.init();
      final restored = await fileList.restoreFileList();
      if (restored > 0) split.syncConfigs(fileList.files);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onExit(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppConstants.appName),
          actions: [
            _buildFileCountChip(),
            _buildThemeMenu(),
            const SizedBox(width: 8),
          ],
        ),
        body: isWide ? _buildWide(context) : _buildNarrow(context),
        bottomNavigationBar: isWide ? null : _buildBottomNav(),
      ),
    );
  }

  Widget _buildFileCountChip() {
    return Consumer<FileListState>(
      builder: (context, state, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${state.count} 文件', style: Theme.of(context).textTheme.labelMedium),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeMenu() {
    return Consumer<AppState>(
      builder: (context, state, _) => PopupMenuButton<ThemeMode>(
        icon: Icon(state.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
        tooltip: '主题切换',
        onSelected: state.setThemeMode,
        itemBuilder: (ctx) => const [
          PopupMenuItem(value: ThemeMode.system, child: ListTile(leading: Icon(Icons.settings_brightness), title: Text('跟随系统'), dense: true)),
          PopupMenuItem(value: ThemeMode.light, child: ListTile(leading: Icon(Icons.light_mode), title: Text('浅色'), dense: true)),
          PopupMenuItem(value: ThemeMode.dark, child: ListTile(leading: Icon(Icons.dark_mode), title: Text('深色'), dense: true)),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _section.index,
          onDestinationSelected: (i) => setState(() => _section = NavSection.values[i]),
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.upload_file), label: Text('导入')),
            NavigationRailDestination(icon: Icon(Icons.grid_on), label: Text('分割')),
            NavigationRailDestination(icon: Icon(Icons.download), label: Text('导出')),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildSection()),
              const ProgressPanel(),
            ],
          ),
        ),
        const SizedBox(
          width: 320,
          child: Column(
            children: [
              Expanded(child: LogPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildSection()),
        const ProgressPanel(),
        const LogPanel(),
      ],
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case NavSection.import:
        return const ImportPanel();
      case NavSection.split:
        return const SplitPanel();
      case NavSection.export:
        return const ExportPanel();
    }
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _section.index,
      onDestinationSelected: (i) => setState(() => _section = NavSection.values[i]),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.upload_file), label: '导入'),
        NavigationDestination(icon: Icon(Icons.grid_on), label: '分割'),
        NavigationDestination(icon: Icon(Icons.download), label: '导出'),
      ],
    );
  }

  /// 退出保存逻辑 (SRS 4.1.5: 弹窗询问是否保留本次文件列表)
  Future<void> _onExit(BuildContext context) async {
    final fileList = context.read<FileListState>();
    if (fileList.count == 0) {
      Navigator.of(context).pop();
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出程序'),
        content: const Text('是否保留本次文件列表?\n\n选择「是」: 下次启动自动恢复\n选择「否」: 清空列表并退出'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('取消')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('否, 清空退出'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('是, 保留退出'),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (result) {
      await fileList.setKeepFileList(true);
      await fileList.saveFileList();
    } else {
      await fileList.setKeepFileList(false);
      await fileList.clearSavedFileList();
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}
