# Docudis for Windows

Docudis 的 Windows 版（Flutter Desktop，同一份代码也能在 macOS 上运行）。在本机识别并匿名化文本、PDF、Word 文档和图片，不上传任何内容。功能基准是 [docudis-android](https://github.com/stonetech-pxia/docudis-android)，架构和待定事项见 [HANDOFF-windows-2026-10-01.md](HANDOFF-windows-2026-10-01.md)。

- 技术栈：Flutter 3.47 / Dart 3.13、Riverpod 3
- 界面语言：English、Español、Français、中文（默认跟随系统）
- 引擎：检测、合并、匿名化、还原、语言识别全部走 docudis-core，NER 走 docudis-ner（都是 Rust，经 C ABI 调用）。版本锁定在 [tool/native.lock.json](tool/native.lock.json)，Dart 绑定在 `pubspec.yaml` 里按同一个 commit 引用。

## 目前能做的

- 粘贴文本（也可以按 ⌘V / Ctrl+V）→ 匿名化 → 结果页（匿名化后 / 原文、复制、另存为）
- 上传或把文件拖进窗口：txt、md、csv、docx、有文字层的 PDF；docx 和 PDF 会另外生成匿名化后的副本
- 审阅页（点占位符显示原值、点普通文字遮住、一键遮住全部金额 / 日期）、还原页（检查回复是否属于这份文档）、历史记录
- 还没有：图片和扫描版 PDF（等 OCR 方案）、词典页、账户页、"发送到"AI 应用。PDF 里只要有一页没有文字层，就不生成 PDF 副本，只输出文字，避免扫描页未经遮盖就流出去。

## 目录结构

```text
lib/
  theme/              Clay 主题和组件（从 docudis-android 复制；ClaySideNav 是桌面新增）
  l10n/               ARB 文案（从 docudis-android 复制，加了桌面用的几条）
  home/               外层布局：宽窗口用侧边栏，窄于 720 px 时改用底部导航栏；每个标签页有自己的页面栈
  anonymize/
    engine/           原生库的位置、NER 模型加载
    input/ output/    文本提取，docx / PDF 匿名化副本
    storage/          历史记录（<app support>/records，和 Android 同样的格式，明文）
    ui/               保护、结果、审阅、还原、历史页面
packages/docudis_pdf/ PDF 匿名化（从 docudis-android 复制）
tool/                 原生库构建、模型安装、版本锁定
windows/  macos/      Flutter runner
```

界面代码是从 docudis-android 复制过来的，不和它共享包，桌面版可以自由改动。

## 开发（macOS，Apple 芯片）

第一次需要准备原生库和模型：

```bash
tool/prepare_native.sh
```

```bash
tool/fetch_models.sh
```

- `prepare_native.sh` 按锁定版本拉取并编译 docudis-core（带语言识别）和 docudis-ner，下载并校验 ONNX Runtime，产物放在 `build/native/macos/`，Xcode 构建时会复制进 `Docudis.app/Contents/Frameworks`。有本地 checkout 时可以用 `DOCUDIS_CORE_SOURCE=../docudis-core` / `DOCUDIS_NER_SOURCE=../docudis-ner` 省掉克隆（必须在锁定的 commit 上）。
- `fetch_models.sh` 把 NER 模型装到 `~/Library/Application Support/com.stonetech.docudis/models/`。模型在私有的 Hugging Face 仓库，需要先 `huggingface-cli login`；已经有模型文件时，先复制到这个目录，脚本校验 SHA-256 通过就不会重新下载。
- 没有模型时 App 照样能用，只是只跑规则和名单，并在页面上提示。

```bash
flutter test
```

```bash
flutter test integration_test/flow_test.dart -d macos
```

```bash
flutter run -d macos
```

集成测试用真实的原生库和模型跑完整流程（粘贴 → 匿名化 → 审阅 → 还原，以及 PDF、docx）。

说明：

- macOS 关掉了 App 沙盒（不上 App Store）。本地运行不需要 Apple 开发者账号；正式对外发布 Mac 版才需要 Developer ID 签名和公证。
- ONNX Runtime 1.30 没有 Intel Mac 版本，目前只支持 Apple 芯片。
- Windows：`flutter build windows` 只能在 Windows 上运行，需要 Visual Studio 的"使用 C++ 的桌面开发"组件；原生库的 Windows 构建脚本和打包规则还没写（三个 DLL 放在 exe 旁边即可被找到）。
