# 图片分割预览与PDF合成工具

基于 Flutter 的 Windows 桌面端图片分割与 PDF 合成工具。

![1拖拽上传](./res/1拖拽上传.gif)
> 1. 拖拽上传图片，支持批量导入

![2分割页面](./res/2分割页面.png)
> 2. 选择分割预设，快速完成页面分割

![3图片切换](./res/3图片切换.gif)
> 3. 在列表切换多张图片，独立保存每张分割参数

![4图片微调](./res/4图片微调.gif)
> 4. 拖拽分割线，精细微调切片边界

![5导出](./res/5导出.gif)
> 5. 导出切片图片，或合并输出PDF文件

## ✨ 功能

- **图片导入**：支持 PNG / JPG / JPEG / BMP / TIFF，拖拽或文件选择导入，支持多文件有序列表
- **图片分割**：快速等分切割 + 独立微调拖拽分割线，实时预览分割效果
- **切片导出**：导出为 PNG / JPG / BMP / TIFF，自定义输出目录与文件命名规则
- **PDF 合并**：多文件切片按顺序合并为单个 PDF，每页保留原图尺寸
- **预设管理**：内置 `1×2`、`2×1`、`1×3`、`3×1` 分割预设，支持保存自定义分割方案
- **主题切换**：Material 3 设计，浅色 / 深色主题一键切换
- **配置持久化**：主题偏好、输出路径、自定义分割预设自动本地保存

## 📥 直接下载（普通用户）
无需编译，前往 GitHub Releases 下载 Windows 已打包版本：
> https://github.com/amiena1011/ImageSplit/releases

下载对应文件，直接运行安装程序.

## 🖥️ 开发构建环境要求（开发者）

- Windows 10 / 11（64 位）
- Flutter 3.x（stable 或 master channel）
- JDK 17
- Visual Studio 2022（需要安装 **C++ 桌面开发**工作负载）

## 🚀 快速开始（开发者）

```powershell
# 拉取项目依赖
flutter pub get

# Debug模式运行程序
flutter run -d windows

# 编译 Release 正式版本
flutter build windows --release