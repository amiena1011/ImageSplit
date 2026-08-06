@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ======================================================
echo                Flutter Windows打包脚本
echo        图标源文件：项目根目录 iconico.ico
echo ======================================================
echo.

:: 1. 校验是否存在iconico.ico
if not exist "iconico.ico" (
    echo [错误] 未找到图标文件：iconico.ico
    echo 请确认该文件放在项目根目录，和build.bat同一文件夹！
    echo.
    pause
    exit /b 1
)
echo [√] 检测到图标文件 iconico.ico
echo.

:: 2. 校验windows资源目录是否存在
if not exist "windows\runner\resources\" (
    echo [错误] 找不到flutter windows项目目录
    echo 当前文件夹不是flutter项目根目录，请切换目录！
    echo.
    pause
    exit /b 1
)
echo [√] 检测到Windows项目资源目录
echo.

:: 3. 复制ico到目标位置
echo [步骤1/4] 正在复制图标到windows资源目录...
copy /Y "iconico.ico" "windows\runner\resources\app_icon.ico"
if !errorlevel! neq 0 (
    echo [错误] 图标文件复制失败！
    pause
    exit /b 1
)
echo [√] 图标复制完成
echo.

:: 4. flutter clean
echo [步骤2/4] 执行 flutter clean 清理旧构建缓存
flutter clean
if !errorlevel! neq 0 (
    echo [错误] flutter clean 执行失败，请检查flutter环境！
    pause
    exit /b 1
)
echo [√] 缓存清理完成
echo.

:: 5. flutter pub get
echo [步骤3/4] 执行 flutter pub get 拉取依赖
flutter pub get
if !errorlevel! neq 0 (
    echo [错误] 依赖获取失败，请检查网络与pubspec.yaml
    pause
    exit /b 1
)
echo [√] 依赖安装完成
echo.

:: 6. 正式打包 windows release
echo [步骤4/4] 开始构建 Windows Release安装包，耗时较长，请耐心等待...
echo 注意：首次构建会下载编译工具，请不要关闭窗口！
echo.
flutter build windows --release
if !errorlevel! neq 0 (
    echo.
    echo ======================================================
    echo                [打包失败！]
    echo 请查看上方日志，定位gradle/编译错误。
    echo ======================================================
    pause
    exit /b 1
)

:: 打包成功提示
echo.
echo ======================================================
echo                  ✅ 打包构建成功
echo 输出exe目录：build\windows\x64\release\runner
echo.
echo 提示：
echo 1. 如果exe图标没变化：执行flutter clean后重新完整构建
echo 2. Windows会缓存图标，旧exe不会自动刷新，看新生成的exe
echo 3. iconico.ico必须是真正ico文件，不能直接改png后缀
echo ======================================================
pause
endlocal