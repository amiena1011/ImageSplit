// 任务进度面板 (SRS 4.5 模块6: 任务进度条)
// 全局任务进度条: 分割、导出、PDF转换全流程实时展示百分比进度

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/task_state.dart';

class ProgressPanel extends StatelessWidget {
  const ProgressPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskState>(
      builder: (context, state, _) {
        if (!state.running && !state.hasError && state.progress == 0) {
          return const SizedBox.shrink();
        }
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (state.running)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else if (state.hasError)
                      const Icon(Icons.error_outline, color: Colors.red, size: 18)
                    else
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.hasError ? '任务出错' : state.statusText,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('${state.progressPercent}%'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: state.hasError ? null : (state.progress == 0 ? null : state.progress),
                ),
                if (state.hasError) ...[
                  const SizedBox(height: 6),
                  Text(state.errorText, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
