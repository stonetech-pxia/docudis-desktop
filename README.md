# Docudis for Windows

Docudis 的 Windows 版（Flutter Desktop）。在本机识别并匿名化文本、PDF、Word 文档和图片，不上传任何内容。功能基准是 [docudis-android](https://github.com/stonetech-pxia/docudis-android)，架构和待定事项见 [HANDOFF-windows-2026-10-01.md](HANDOFF-windows-2026-10-01.md)。

- 技术栈：Flutter 3.47 / Dart 3.13、Riverpod 3
- 界面语言：English、Español、Français、中文（默认跟随系统）
- 引擎：docudis-core、docudis-ner（Rust，经 C ABI 调用，尚未接入）

## 目录结构

```text
lib/
  theme/        Clay 主题和组件（从 docudis-android 复制；ClaySideNav 是 Windows 新增）
  l10n/         ARB 文案（从 docudis-android 复制）
  engine/       EntityType 的临时本地副本，等 docudis_ffi 有了类型化模型后替换
  home/         外层布局：宽窗口用侧边栏，窄于 720 px 时改用底部导航栏
  anonymize/ui/ 保护、历史页面（目前是空壳）
windows/        Flutter Windows runner
```

界面代码是从 docudis-android 复制过来的，不和它共享包，Windows 版可以自由改动。

## 开发

```bash
flutter test
```

`flutter build windows` 只能在 Windows 上运行，需要 Visual Studio 的"使用 C++ 的桌面开发"组件。
