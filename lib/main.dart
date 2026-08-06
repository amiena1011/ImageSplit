// 应用入口 (SRS 1.4: Flutter(Dart) 单代码库双端部署)
// Windows 绿色免安装EXE / Android APK 安装包

import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
