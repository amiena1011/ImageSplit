# 图片分割预览与PDF合成工具

基于 Flutter 的 Windows 桌面端图片分割与 PDF 合成工具。

## 功能

- **图片导入**：支持 PNG / JPG / JPEG / BMP / TIFF，拖拽或文件选择导入，支持多文件有序列表
- **图片分割**：快速等分切割 + 独立微调拖拽分割线，实时预览
- **切片导出**：导出为 PNG / JPG / BMP / TIFF，自定义输出目录与命名
- **PDF 合并**：多文件切片按顺序合并为单个 PDF，每页使用原图尺寸
- **预设管理**：内置 1×2、2×1、1×3、3×1，支持自定义预设
- **主题切换**：Material 3 设计，支持浅色 / 深色主题
- **配置持久化**：主题、输出路径、自定义预设自动保存

## 环境要求

- Windows 10 / 11（64 位）
- Flutter 3.x（stable 或 master channel）
- JDK 17
- Visual Studio 2022（含 C++ 桌面开发工作负载）

## 快速开始

```powershell
# 安装依赖
flutter pub get

# 运行（Debug）
flutter run -d windows

# 构建 Release 版本
flutter build windows --release
```

构建产物位于 `build\windows\x64\runner\Release\`。

## 使用说明

详见 [INSTALL.txt](INSTALL.txt)。
