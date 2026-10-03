# Docudis for Windows

Docudis 的 Windows 版（Flutter Desktop，同一份代码也能在 macOS 上运行）。在本机识别并匿名化文本、PDF、Word 文档和图片，不上传任何内容。功能基准是 [docudis-android](https://github.com/stonetech-pxia/docudis-android)，架构和待定事项见 [HANDOFF-windows-2026-10-01.md](HANDOFF-windows-2026-10-01.md)。

- 技术栈：Flutter 3.47 / Dart 3.13、Riverpod 3
- 界面语言：English、Español、Français、中文（默认跟随系统）
- 引擎：检测、合并、匿名化、还原、语言识别全部走 docudis-core，NER 走 docudis-ner（都是 Rust，经 C ABI 调用）。版本锁定在 [tool/native.lock.json](tool/native.lock.json)，Dart 绑定在 `pubspec.yaml` 里按同一个 commit 引用。

## 目前能做的

桌面式的界面，颜色沿用 Android 的 Clay：

- **工作区**（保护）：工具栏（新建 ⌘N、打开 ⌘O、粘贴 ⌘V、匿名化 ⌘↩、复制 ⌘⇧C、另存为 ⌘S、还原回复 ⌘R；Windows 上是 Ctrl），左栏原文、右栏匿名化结果、最右是检测结果列表，底部状态栏显示语言和模型。没打开记录时左栏就是编辑器，可以直接输入、粘贴，或把文件拖进窗口。
- 改遮盖：在检测结果里勾选或取消，或者直接点原文（点检测到的内容切换遮盖，点普通文字把那一段遮住），改动即时保存。
- 文件：txt、md、csv、docx、有文字层的 PDF；docx 和 PDF 会另外生成匿名化后的副本，用"另存为"保存。
- **还原回复**：单独一页，左边贴 AI 回复，右边是还原结果，并检查回复是否属于这份文档。
- **历史记录**：可排序的表格，点一行就在工作区里打开；侧边栏下方列出最近的文档。
- **词典**："总是遮住"和"从不遮住"两个列表并排，可以输入添加，也可以从"最近手动遮住 / 恢复显示的"推荐里一键加入；"只遮住这个列表"打开后只查列表里的词。在工作区的检测结果上点右键，也能直接加入两个列表。改动从下一份文档开始生效。
- **设置**：界面语言、记录保存位置（可在文件夹中打开）、清除本机数据、隐私政策、联系方式、版本号。没有账户的概念。
- 还没有：图片和扫描版 PDF（等 OCR 方案）、"发送到"AI 应用。PDF 里只要有一页没有文字层，就不生成 PDF 副本，只输出文字，避免扫描页未经遮盖就流出去。

## 目录结构

```text
lib/
  theme/              Clay 主题和组件（从 docudis-android 复制，尺寸改成桌面的；desk_widgets 是桌面新增的工具栏和面板）
  l10n/               ARB 文案（从 docudis-android 复制，加了桌面用的几条）
  home/               外层布局：宽窗口用侧边栏，窄于 720 px 时改用底部导航栏；每个标签页有自己的页面栈
  anonymize/
    engine/           原生库的位置、NER 模型加载
    input/ output/    文本提取，docx / PDF 匿名化副本
    storage/          历史记录（<app support>/records，和 Android 同样的格式，明文）
    ui/               工作区（原文、匿名化结果、检测结果）、还原、历史页面
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
- 可选模型 OpenAI Privacy Filter：`tool/fetch_models.sh openai_privacy_filter`（约 950 MB，加载后约 1.6 GB 内存，每 1000 字符约多 0.3 秒）。App 会加载 `models/` 下所有已安装的模型（目前是 `xlmr_ner_docudis` 和 `openai_privacy_filter`），把它们的结果一起交给 core 合并；没装就不加载。
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

集成测试用真实的原生库和模型跑完整流程（粘贴 → 匿名化 → 审阅 → 还原、词典、PDF、docx），记录和词典都写到临时文件夹，不碰本机真实数据。

说明：

- macOS 关掉了 App 沙盒（不上 App Store）。本地运行不需要 Apple 开发者账号；正式对外发布 Mac 版才需要 Developer ID 签名和公证。
- ONNX Runtime 1.30 没有 Intel Mac 版本，目前只支持 Apple 芯片。
- Windows：`flutter build windows` 只能在 Windows 上运行，需要 Visual Studio 的"使用 C++ 的桌面开发"组件；原生库的 Windows 构建脚本和打包规则还没写（三个 DLL 放在 exe 旁边即可被找到）。

## 许可证

[GNU AGPL-3.0](LICENSE)，版权归 stonetech 所有，见 [NOTICE](NOTICE)。打包进 App 的 docudis-core 和 docudis-ner 原生库是 Apache-2.0。设置页的「开源许可」列出 App 所用第三方软件的许可证，由 `tool/generate_licenses.py` 生成。

需要不受 AGPL 约束的商业授权，请联系 stonetechdigital@gmail.com。

## 参与

欢迎提 issue，但目前不接受代码 PR，见 [CONTRIBUTING.md](CONTRIBUTING.md)。
