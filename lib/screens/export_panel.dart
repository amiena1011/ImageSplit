// 导出面板 (SRS 4.3 模块4: 导出输出配置模块)
// 路径(双端差异化) + 命名规则 + 格式画质 + PDF合并双模式 + 文件夹策略

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/export_config.dart';
import '../state/file_list_state.dart';
import '../state/split_state.dart';
import '../state/task_state.dart';
import '../services/config_service.dart';
import '../services/export_service.dart';
import '../services/log_service.dart';

class ExportPanel extends StatefulWidget {
  const ExportPanel({super.key});

  @override
  State<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends State<ExportPanel> {
  late ExportConfig _config;
  bool _inited = false;
  ExportResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    if (!_inited) {
      _inited = true;
      _config = ExportConfig();
      _initConfig(context);
    }
    return ChangeNotifierProvider.value(
      value: _config,
      child: Consumer3<FileListState, SplitState, TaskState>(
        builder: (context, fileList, split, task, _) {
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
                        width: 360,
                        child: _buildConfigPanel(context, fileList, split, task),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: _buildSummary(context, fileList, split)),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SizedBox(
                      height: 380,
                      child: _buildConfigPanel(context, fileList, split, task),
                    ),
                    const Divider(height: 1),
                    Expanded(child: _buildSummary(context, fileList, split)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 导出配置面板 (左/上): 路径 + 格式 + PDF选项 + 导出按钮
  Widget _buildConfigPanel(BuildContext context, FileListState fileList, SplitState split, TaskState task) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPath(context),
          const SizedBox(height: 12),
          _buildFormat(context),
          const SizedBox(height: 12),
          _buildPdfOption(context),
          const SizedBox(height: 12),
          if (!_config.mergePdf) _buildFolderStrategy(context),
          const SizedBox(height: 12),
          _buildNamingHint(context),
          const SizedBox(height: 16),
          _buildExportButton(context, fileList, split, task),
        ],
      ),
    );
  }

  Future<void> _initConfig(BuildContext context) async {
    final configService = context.read<ConfigService>();
    final lastPath = await configService.getLastOutputPath();
    if (lastPath.isNotEmpty) {
      _config.outputDir = lastPath;
    } else {
      // 默认输出路径 (SRS 4.3.1)
      try {
        if (PlatformUtils.isAndroid) {
          final dir = await getExternalStorageDirectory();
          _config.outputDir = dir?.path ?? (await getDownloadsDirectory())?.path ?? '';
        } else {
          final dir = await getDownloadsDirectory();
          _config.outputDir = dir?.path ?? '';
        }
      } catch (_) {
        _config.outputDir = '';
      }
    }
    if (mounted) setState(() {});
  }

  /// 输出路径 (SRS 4.3.1: Windows 自定义记忆; Android 固定下载目录)
  Widget _buildPath(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('输出路径', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _config.outputDir.isEmpty ? '未选择' : _config.outputDir,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (PlatformUtils.isWindows) ...[
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () => _pickDir(context),
                    tooltip: '选择文件夹',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      final dir = await getDownloadsDirectory();
                      setState(() => _config.outputDir = dir?.path ?? '');
                    },
                    tooltip: '重置为默认路径',
                  ),
                ],
              ],
            ),
            if (PlatformUtils.isAndroid)
              Text('Android 固定保存至下载/私有存储目录', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDir(BuildContext context) async {
    final selected = await FilePicker.platform.getDirectoryPath();
    if (selected == null) return;
    setState(() => _config.outputDir = selected);
    await context.read<ConfigService>().setLastOutputPath(selected);
    context.read<LogService>().info('设置输出路径: $selected');
  }

  /// 格式与画质 (SRS 4.3.3)
  Widget _buildFormat(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('输出格式与画质', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: AppConstants.exportFormats.map((fmt) {
                final f = ExportFormat.values.byName(fmt.toLowerCase());
                return ChoiceChip(
                  label: Text(fmt),
                  selected: _config.format == f,
                  onSelected: (_) => setState(() => _config.format = f),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // TIFF 画质置灰 (SRS 4.3.3: 固定无损)
            if (_config.qualityEditable) ...[
              Text('画质: ${_config.quality}', style: Theme.of(context).textTheme.bodySmall),
              Slider(
                value: _config.quality.toDouble(),
                min: 10,
                max: 100,
                divisions: 9,
                label: _config.quality.toString(),
                onChanged: (v) => setState(() => _config.quality = v.round()),
              ),
            ] else
              Text('TIFF 固定无损输出', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// PDF 合并选项 (SRS 4.3.4 二选一)
  Widget _buildPdfOption(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF 合并', style: Theme.of(context).textTheme.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('合并为 PDF'),
              subtitle: const Text('开启: 切片合并为PDF; 关闭: 导出图片切片'),
              value: _config.mergePdf,
              onChanged: (v) => setState(() => _config.mergePdf = v),
            ),
            if (_config.mergePdf) ...[
              const Divider(),
              Text('PDF 分辨率: ${_config.pdfDpi} DPI', style: Theme.of(context).textTheme.bodySmall),
              Slider(
                value: _config.pdfDpi.toDouble(),
                min: 72,
                max: 600,
                divisions: 11,
                label: _config.pdfDpi.toString(),
                onChanged: (v) => setState(() => _config.pdfDpi = v.round()),
              ),
              Text('压缩等级: ${_config.pdfCompression}', style: Theme.of(context).textTheme.bodySmall),
              Slider(
                value: _config.pdfCompression.toDouble(),
                min: 0,
                max: 9,
                divisions: 9,
                label: _config.pdfCompression.toString(),
                onChanged: (v) => setState(() => _config.pdfCompression = v.round()),
              ),
              const SizedBox(height: 4),
              Text('统一页面尺寸, 切片居中, 空白白色留白填充', style: Theme.of(context).textTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }

  /// 文件夹策略 (SRS 4.3.4 关闭合并PDF: 模式A/B)
  Widget _buildFolderStrategy(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('切片文件夹策略', style: Theme.of(context).textTheme.titleSmall),
            RadioListTile<SliceFolderStrategy>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: SliceFolderStrategy.perImage,
              groupValue: _config.folderStrategy,
              title: const Text('每张原图独立文件夹 (模式A)'),
              onChanged: (v) => setState(() => _config.folderStrategy = v!),
            ),
            RadioListTile<SliceFolderStrategy>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: SliceFolderStrategy.unified,
              groupValue: _config.folderStrategy,
              title: const Text('统一任务文件夹 (模式B)'),
              onChanged: (v) => setState(() => _config.folderStrategy = v!),
            ),
          ],
        ),
      ),
    );
  }

  /// 命名规则提示 (SRS 4.3.2)
  Widget _buildNamingHint(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('命名规则', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('时间戳_原文件名_随机编码_子图编号.扩展名', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('示例: 20260805_143000_photo_a1b2c3_1.png', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.lock, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(child: Text('原始文件只读, 绝不修改源文件', style: Theme.of(context).textTheme.labelSmall)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, FileListState fileList, SplitState split, TaskState task) {
    final canExport = fileList.count > 0 && _config.outputDir.isNotEmpty && !task.running;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: canExport ? () => _doExport(context, fileList, split, task) : null,
          icon: const Icon(Icons.download_for_offline),
          label: const Text('开始导出'),
        ),
        if (_lastResult != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('上次导出: ${_lastResult!.sliceCount} 个切片', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(_lastResult!.taskDir, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _openDirectory(_lastResult!.taskDir),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('打开输出目录'),
                    ),
                    if (_lastResult!.files.isNotEmpty)
                      FilledButton.tonalIcon(
                        onPressed: () => _openFile(_lastResult!.files.last),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text('查看${_config.mergePdf ? 'PDF' : '文件'}'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openDirectory(String path) async {
    try {
      if (PlatformUtils.isWindows) {
        await Process.run('explorer', [path]);
      } else {
        await Process.run('open', [path]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开目录: $e')),
        );
      }
    }
  }

  Future<void> _openFile(String path) async {
    try {
      if (PlatformUtils.isWindows) {
        await Process.run('start', ['', path], runInShell: true);
      } else {
        await Process.run('open', [path]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开文件: $e')),
        );
      }
    }
  }

  Future<void> _doExport(BuildContext context, FileListState fileList, SplitState split, TaskState task) async {
    final log = context.read<LogService>();
    final exportService = ExportService();
    task.start('准备导出...');
    log.info('开始导出任务: ${fileList.count} 个文件');

    try {
      final result = await exportService.export(
        files: fileList.orderedFiles,
        configs: split.allConfigs,
        exportConfig: _config,
        onProgress: (p, msg) => task.update(p, msg),
        onLog: (msg, {error = false}) {
          if (error) {
            log.error(msg);
          } else {
            log.info(msg);
          }
        },
      );
      task.finish('导出完成: ${result.sliceCount} 个切片');
      log.success('导出完成, 共 ${result.sliceCount} 个切片, 输出目录: ${result.taskDir}');
      setState(() => _lastResult = result);
      await context.read<ConfigService>().setLastOutputPath(_config.outputDir);
    } catch (e) {
      task.error('导出失败: $e');
      log.error('导出失败', detail: e.toString());
    }
  }

  /// 汇总预览
  Widget _buildSummary(BuildContext context, FileListState fileList, SplitState split) {
    int totalSlices = 0;
    for (final f in fileList.files) {
      final c = split.getConfig(f.id);
      if (c != null) totalSlices += c.totalSlices;
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('导出汇总', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _summaryRow(context, '源文件数', '${fileList.count}'),
          _summaryRow(context, '预计切片总数', '$totalSlices'),
          _summaryRow(context, '输出格式', _config.formatLabel),
          _summaryRow(context, '导出模式', _config.mergePdf ? '合并 PDF' : '图片切片'),
          _summaryRow(context, '输出目录', _config.outputDir.isEmpty ? '未选择' : _config.outputDir),
          const SizedBox(height: 16),
          // 约束提示 (SRS 4.3.5: 单次任务完成后不支持二次重分割)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(child: Text('单次任务完成后不支持二次重分割, 修改参数需新建任务', style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
