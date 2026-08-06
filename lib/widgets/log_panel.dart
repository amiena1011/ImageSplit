// 操作日志面板 (SRS 4.5 模块6: 简易操作日志面板)
// 记录文件导入、参数配置、分割、导出、报错等全量操作记录

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/log_entry.dart';
import '../services/log_service.dart';

class LogPanel extends StatelessWidget {
  const LogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LogService>(
      builder: (context, service, _) {
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 18),
                    const SizedBox(width: 6),
                    Text('操作日志', style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    if (service.entries.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, size: 18),
                        onPressed: service.clear,
                        tooltip: '清空日志',
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: service.entries.isEmpty
                      ? Center(child: Text('暂无日志', style: Theme.of(context).textTheme.bodySmall))
                      : ListView.builder(
                          itemCount: service.entries.length,
                          itemBuilder: (context, index) {
                            final entry = service.entries[index];
                            return _LogTile(entry: entry);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LogTile extends StatelessWidget {
  final LogEntry entry;
  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.level) {
      LogLevel.info => Theme.of(context).colorScheme.onSurfaceVariant,
      LogLevel.warning => Colors.orange,
      LogLevel.error => Colors.red,
      LogLevel.success => Colors.green,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.timeFormatted, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontFeatures: [const FontFeature.tabularFigures()])),
          const SizedBox(width: 6),
          Text(entry.levelIcon, style: TextStyle(color: color)),
          const SizedBox(width: 4),
          Expanded(child: Text(entry.message, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
