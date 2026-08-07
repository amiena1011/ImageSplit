// PDF转换服务 - 处理PDF转图片功能
// 调用Python exe进行PDF处理，将结果添加到文件列表

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/file_item.dart';
import '../services/config_service.dart';
import '../services/file_service.dart';
import '../state/file_list_state.dart';
import 'package:file_picker/file_picker.dart';

class PdfConvertService {
  /// 调用PDF工具查询PDF总页数
  static Future<int> getPdfInfo(String pdfPath) async {
    try {
      final exePath = _getPdfExePath();
      print('Using PDF exe at: $exePath'); // 调试信息

      // 检查exe是否存在
      if (!File(exePath).existsSync()) {
        throw Exception('PDF工具不存在: $exePath');
      }

      // 对路径进行转义
      final escapedPath = pdfPath.replaceAll('"', '\\"');
      final args = ['info', escapedPath];
      print('Running with args: $args'); // 调试信息

      final result = await Process.run(exePath, args);

      print('Exit code: ${result.exitCode}');
      print('Stdout: ${result.stdout}');
      print('Stderr: ${result.stderr}');

      if (result.exitCode != 0) {
        throw Exception('查询PDF信息失败: ${result.stderr}');
      }

      // 从输出中解析页数
      final output = result.stdout.toString();
      final RegExp pattern = RegExp(r'PDF总页数：(\d+)');
      final match = pattern.firstMatch(output);

      if (match != null) {
        return int.parse(match.group(1)!);
      } else {
        throw Exception('无法解析PDF页数信息');
      }
    } catch (e) {
      throw Exception('获取PDF信息失败: $e');
    }
  }

  /// 执行PDF转图片转换（不依赖FileListState）
  static Future<List<FileItem>> convertPdfToImages({
    required String pdfPath,
    required String pageExpr,
    FileService? fileService,
    FileListState? fileList,
  }) async {
    try {
      final exePath = _getPdfExePath();
      print('Using PDF exe for convert: $exePath');
      print('PDF path: $pdfPath');
      print('Page expr: $pageExpr');

      // 解析页码列表
      final totalPages = await getPdfInfo(pdfPath);
      final pages = _parsePageExpression(pageExpr, totalPages);

      // 获取保存目录
      final saveDir = await getPdfSaveDir();

      // 更新配置中的保存位置
      try {
        final config = ConfigService();
        await config.setLastOutputPath(saveDir);
      } catch (e) {
        print('Warning: Could not save output path preference: $e');
      }

      print('Saving converted files to: $saveDir');

      // 创建临时输出目录
      final tempDir = Directory.systemTemp.createTempSync('pdf_convert_');
      final outputDir = tempDir.path;

      // 转义路径并执行转换
      final escapedPdfPath = pdfPath.replaceAll('"', '\\"');
      final escapedPageExpr = pageExpr.replaceAll('"', '\\"');
      final escapedOutputDir = outputDir.replaceAll('"', '\\"');
      final args = ['convert', escapedPdfPath, escapedPageExpr, '-o', escapedOutputDir];

      final result = await Process.run(exePath, args);

      if (result.exitCode != 0) {
        throw Exception('PDF转换失败: ${result.stderr}');
      }

      // 读取转换后的图片文件
      final convertedFiles = <FileItem>[];
      final effectiveFileService = fileService ?? FileService();

      await for (final entity in Directory(outputDir).list()) {
        if (entity is File &&
            (entity.path.endsWith('.png') || entity.path.endsWith('.jpg'))) {
          final file = entity as File;
          final stat = await file.stat();

          // 使用页码 + 时间戳作为新文件名
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final originalName = path.basenameWithoutExtension(file.path);
          final extension = path.extension(file.path);

          // 找到对应的页码
          int pageIndex = pages[convertedFiles.length];

          // 格式化页码为3位数字
          final pageName = 'page_${pageIndex.toString().padLeft(3, '0')}_${originalName}';
          final uniqueName = '${timestamp}_${pageName}${extension}';
          final permanentPath = path.join(saveDir, uniqueName);

          // 复制文件到自定义目录
          await file.copy(permanentPath);

          // 创建FileItem
          final fileItem = FileItem.createPdfConverted(
            id: '${timestamp}_$pageIndex',
            path: permanentPath,
            name: uniqueName,
            sizeBytes: stat.size,
            pageNumber: pageIndex,
          );
          convertedFiles.add(fileItem);
        }
      }

      // 按页码排序
      convertedFiles.sort((a, b) {
        final aPage = a.pdfPageNumber ?? 0;
        final bPage = b.pdfPageNumber ?? 0;
        return aPage.compareTo(bPage);
      });

      // 添加到文件列表（如果提供了fileList）
      if (fileList != null) {
        fileList.addAll(convertedFiles);
      }

      // 清理临时目录
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}

      return convertedFiles;
    } catch (e) {
      throw Exception('PDF转换失败: $e');
    }
  }

  /// 执行PDF转图片转换（原方法，保留向后兼容）
  static Future<String> convertPdfToImagesRaw({
    required String pdfPath,
    required String pageExpr,
    String? outputDir,
  }) async {
    try {
      final exePath = _getPdfExePath();
      print('Using PDF exe for convert: $exePath');
      print('PDF path: $pdfPath');
      print('Page expr: $pageExpr');
      print('Output dir: $outputDir');

      // 转义路径
      final escapedPdfPath = pdfPath.replaceAll('"', '\\"');
      final escapedPageExpr = pageExpr.replaceAll('"', '\\"');
      final escapedOutputDir = outputDir != null ? outputDir.replaceAll('"', '\\"') : null;

      final args = ['convert', escapedPdfPath, escapedPageExpr];

      // 添加输出目录参数（如果指定）
      if (escapedOutputDir != null) {
        args.addAll(['-o', escapedOutputDir]);
      }

      print('Running with args: $args');

      final result = await Process.run(exePath, args);

      print('Exit code: ${result.exitCode}');
      print('Stdout: ${result.stdout}');
      print('Stderr: ${result.stderr}');

      if (result.exitCode != 0) {
        throw Exception('PDF转换失败: ${result.stderr}');
      }

      return result.stdout.toString();
    } catch (e) {
      throw Exception('PDF转换失败: $e');
    }
  }

  /// 获取PDF转换图片的保存目录
  static Future<String> getPdfSaveDir({bool allowCustom = true}) async {
    if (allowCustom) {
      // 尝试获取配置中保存的路径
      final config = ConfigService();
      final customPath = await config.getLastOutputPath();
      if (customPath.isNotEmpty) {
        final customDir = Directory(customPath);
        if (await customDir.exists()) {
          return customDir.path;
        }
      }
    }

    // 使用默认保存目录
    final configDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path.join(configDir.path, 'ImageSplit', 'converted_files'));
    await pdfDir.create(recursive: true);
    return pdfDir.path;
  }

  /// 创建PDF转换对话框窗口
  static Future<void> showPdfConvertDialog(BuildContext context) async {
    final fileList = context.read<FileListState>();
    final fileService = FileService();

    // 选择PDF文件
    final pdfFile = await _selectPdfFile(context);
    if (pdfFile == null) return;

    // 获取PDF总页数
    int totalPages = await _showPdfInfo(context, pdfFile);
    if (totalPages <= 0) return;

    // 选择页码
    final selectedPages = await _selectPdfPages(context, totalPages);
    if (selectedPages.isEmpty) return;

    // 显示确认对话框
    final confirmed = await _showConfirmDialog(
      context,
      pdfFile,
      selectedPages.join(','),
    );
    if (confirmed != true) return;

    // 执行转换
    _executeConversion(
      context,
      pdfFile,
      selectedPages.join(','),
      totalPages,
      fileService,
      fileList,
    );
  }

  // 获取PDF工具exe路径
  static String _getPdfExePath() {
    // 使用完整路径，确保能找到exe
    final currentPath = Directory.current.path;

    // 尝试不同路径
    final possiblePaths = [
      // tool目录
      path.join(currentPath, 'tool', 'PDF转图片.exe'),
      // 直接在当前目录
      path.join(currentPath, 'PDF转图片.exe'),
      // 相对路径
      'tool\\PDF转图片.exe',
      'PDF转图片.exe',
    ];

    for (final path in possiblePaths) {
      if (File(path).existsSync()) {
        print('Found PDF exe at: $path');
        return path;
      }
    }

    throw Exception('找不到PDF转换工具，请确保PDF转图片.exe在tool目录下');
  }

  // 选择PDF文件
  static Future<String?> _selectPdfFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      return result?.files.single.path;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择PDF文件失败: $e')),
        );
      }
      return null;
    }
  }

  // 显示PDF信息并获取页数
  static Future<int> _showPdfInfo(BuildContext context, String pdfPath) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('读取PDF信息'),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text('正在读取PDF页数...')),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );

    try {
      final totalPages = await getPdfInfo(pdfPath);

      // 关闭对话框
      Navigator.of(context).pop();

      // 显示页数信息
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('PDF信息'),
            content: Text('PDF总页数：$totalPages'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }

      return totalPages;
    } catch (e) {
      // 关闭对话框并显示错误
      Navigator.of(context).pop();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('错误'),
            content: Text('读取PDF信息失败: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
      rethrow;
    }
  }

  // 选择页码
  static Future<List<int>> _selectPdfPages(
    BuildContext context,
    int totalPages,
  ) async {
    final controller = TextEditingController();
    final pagesText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择页码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入页码表达式，格式如下：'),
            const SizedBox(height: 8),
            const Text('• 单页: 5'),
            const Text('• 区间: 1-3'),
            const Text('• 混合: "1-3,5,10,12-15"'),
            const SizedBox(height: 8),
            Text('PDF总页数：$totalPages'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '例: 1-5,7,9-12',
                helperText: '注意：页码从1开始',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final input = controller.text;
              if (input.isNotEmpty) {
                Navigator.of(ctx).pop(input);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (pagesText == null) return [];

    // 解析页码表达式
    try {
      final pages = _parsePageExpression(pagesText, totalPages);
      return pages;
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('错误'),
            content: Text('页码格式错误: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
      return [];
    }
  }

  // 解析页码表达式
  static List<int> _parsePageExpression(String expr, int totalPages) {
    final pages = <int>[];
    final parts = expr.split(',');

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) continue;

      if (part.contains('-')) {
        final range = part.split('-');
        if (range.length != 2) {
          throw Exception('区间格式错误: $part');
        }

        final start = int.tryParse(range[0].trim());
        final end = int.tryParse(range[1].trim());

        if (start == null || end == null) {
          throw Exception('页码必须是数字: $part');
        }

        final actualStart = start < 1 ? 1 : start;
        final actualEnd = end > totalPages ? totalPages : end;

        if (actualStart > actualEnd) {
          throw Exception('页码范围错误: $part');
        }

        for (int j = actualStart; j <= actualEnd; j++) {
          pages.add(j);
        }
      } else {
        final page = int.tryParse(part);
        if (page == null) {
          throw Exception('页码必须是数字: $part');
        }
        if (page < 1 || page > totalPages) {
          throw Exception('页码超出范围: $page (1-$totalPages)');
        }
        pages.add(page);
      }
    }

    // 去重并排序
    pages.sort();
    return pages.toSet().toList();
  }

  // 根据页码对转换后的文件进行排序
  static List<FileItem> _sortFilesByPageNumber(List<FileItem> files) {
    return List.from(files)
      ..sort((a, b) {
        // 非PDF转换的文件排在后面
        if (!a.isPdfConverted && !b.isPdfConverted) return 0;
        if (!a.isPdfConverted) return 1;
        if (!b.isPdfConverted) return -1;

        // PDF转换文件按页码排序
        final aPage = a.pdfPageNumber ?? 0;
        final bPage = b.pdfPageNumber ?? 0;
        return aPage.compareTo(bPage);
      });
  }

  // 显示确认对话框
  static Future<bool?> _showConfirmDialog(
    BuildContext context,
    String pdfPath,
    String pageExpr,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认转换'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('将转换 "$pdfPath"'),
                const SizedBox(height: 8),
                Text('选择的页码: $pageExpr'),
                const SizedBox(height: 8),
                const Text('转换后的图片将添加到文件列表'),
                const SizedBox(height: 8),
                const Text('保存位置:'),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: getPdfSaveDir(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.getDirectoryPath();
                        if (result != null) {
                          final config = ConfigService();
                          await config.setLastOutputPath(result);
                          Navigator.of(ctx).pop(true);
                        }
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('选择保存位置'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      icon: const Icon(Icons.save),
                      label: const Text('确认转换'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('取消'),
              ),
            ],
          ),
        );
  }

  // 执行转换
  static void _executeConversion(
    BuildContext context,
    String pdfPath,
    String pageExpr,
    int totalPages,
    FileService fileService,
    FileListState fileList,
  ) async {
    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('转换中...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('正在转换PDF为图片，请稍候...'),
          ],
        ),
      ),
    );

    // 创建临时输出目录
    Directory? tempDir;

    try {
      // 创建临时输出目录
      tempDir = Directory.systemTemp.createTempSync('pdf_convert_');
      final outputDir = tempDir.path;

      // 获取文件服务和列表
      final fileList = context.read<FileListState>();
      final fileService = FileService();

      // 执行转换
      await convertPdfToImages(
        pdfPath: pdfPath,
        pageExpr: pageExpr,
        fileService: fileService,
        fileList: fileList,
      );

      // 关闭进度对话框
      if (context.mounted) Navigator.of(context).pop();

      // 获取最终保存目录
      final saveDir = await getPdfSaveDir();

      // 更新配置中的保存位置
      try {
        final config = ConfigService();
        await config.setLastOutputPath(saveDir);
      } catch (e) {
        print('Warning: Could not save output path preference: $e');
      }

      print('Saving converted files to: $saveDir');

      // 读取转换后的图片文件
      final convertedFiles = <FileItem>[];

      // 解析页码列表
      final pageNumbers = _parsePageExpression(pageExpr, totalPages);

      await for (final entity in Directory(outputDir).list()) {
        if (entity is File &&
            (entity.path.endsWith('.png') || entity.path.endsWith('.jpg'))) {
          final file = entity as File;
          final stat = await file.stat();

          // 根据文件名提取页码（假设文件名包含页码信息）
          // 如果文件名不包含页码，则按顺序分配
          int pageIndex = 0;
          final pagePattern = RegExp(r'(\d+)(?!.*\d)');
          final match = pagePattern.firstMatch(file.path);

          if (match != null) {
            // 从文件名中提取页码
            pageIndex = int.parse(match.group(1)!);
          } else {
            // 如果文件名没有页码，按解析的顺序分配
            pageIndex = pageNumbers[convertedFiles.length];
          }

          // 使用页码 + 时间戳作为新文件名
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final originalName = path.basenameWithoutExtension(file.path);
          final extension = path.extension(file.path);
          final pageName = 'page_${pageIndex.toString().padLeft(3, '0')}_${originalName}';
          final uniqueName = '${timestamp}_${pageName}${extension}';
          final permanentPath = path.join(saveDir, uniqueName);

          // 复制文件到自定义目录
          await file.copy(permanentPath);

          // 创建PDF转换的文件项
          final fileItem = FileItem.createPdfConverted(
            id: '${DateTime.now().millisecondsSinceEpoch}_$pageIndex',
            path: permanentPath,
            name: uniqueName,
            sizeBytes: stat.size,
            pageNumber: pageIndex,
          );
          convertedFiles.add(fileItem);
        }
      }

      // 按页码排序
      convertedFiles.sort((a, b) {
        final aPage = a.pdfPageNumber ?? 0;
        final bPage = b.pdfPageNumber ?? 0;
        return aPage.compareTo(bPage);
      });

      // 添加到文件列表
      if (convertedFiles.isNotEmpty) {
        if (context.mounted) {
          fileList.addAll(convertedFiles);

          // 显示成功消息和保存位置
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功转换 ${convertedFiles.length} 张图片\n保存位置: $saveDir'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

    } catch (e) {
      // 关闭进度对话框并显示错误
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('转换失败'),
            content: Text('PDF转换失败: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } finally {
      // 清理临时目录
      if (tempDir != null) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    }
  }
}

/// 页码输入对话框组件
class PageNumberField extends StatefulWidget {
  const PageNumberField({super.key});

  @override
  State<PageNumberField> createState() => _PageNumberFieldState();
}

class _PageNumberFieldState extends State<PageNumberField> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: '例: 1-5,7,9-12',
        helperText: '注意：页码从1开始',
      ),
      autofocus: true,
    );
  }
}