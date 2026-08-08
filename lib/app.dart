// 应用根组件 (SRS 模块7: Material3 UI 主题系统)
// MultiProvider 注入全部状态/服务, MaterialApp 响应主题切换

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/config_service.dart';
import 'services/file_service.dart';
import 'services/log_service.dart';
import 'state/app_state.dart';
import 'state/file_list_state.dart';
import 'state/split_state.dart';
import 'state/task_state.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ConfigService>(create: (_) => ConfigService()),
        ChangeNotifierProvider<LogService>(create: (_) => LogService()),
        ChangeNotifierProvider<AppState>(
          create: (ctx) => AppState(ctx.read<ConfigService>(), ctx.read<LogService>()),
        ),
        ChangeNotifierProxyProvider<LogService, FileListState>(
          create: (ctx) => FileListState(
            FileService(),
            ctx.read<ConfigService>(),
            ctx.read<LogService>(),
          ),
          update: (ctx, log, prev) => prev ?? FileListState(
            FileService(),
            ctx.read<ConfigService>(),
            log,
          ),
        ),
        ChangeNotifierProxyProvider<LogService, SplitState>(
          create: (ctx) => SplitState(ctx.read<ConfigService>(), ctx.read<LogService>()),
          update: (ctx, log, prev) => prev ?? SplitState(ctx.read<ConfigService>(), log),
        ),
        ChangeNotifierProvider<TaskState>(create: (_) => TaskState()),
      ],
      child: _AppInit(
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            return MaterialApp(
              title: 'ImageSplit',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: appState.themeMode,
              home: appState.initialized
                  ? const HomeScreen()
                  : const _SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}

/// 在 Provider 树内触发 AppState.init()
class _AppInit extends StatefulWidget {
  final Widget child;
  const _AppInit({required this.child});

  @override
  State<_AppInit> createState() => _AppInitState();
}

class _AppInitState extends State<_AppInit> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().init();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
