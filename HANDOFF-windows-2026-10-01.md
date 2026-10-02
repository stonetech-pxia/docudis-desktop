# Docudis Windows：架构与依赖交接（2026-10-01）

这份文件给接手 docudis-windows 的新会话。目标是让你快速理解 Docudis 的整体架构、几个仓库之间的依赖关系，以及 Windows 版必须满足的约束。**请先通读这份文件，再动手；遇到"尚未决定"的事项，先问用户，不要自己拍板。**

## 1. 产品与目标

- Docudis 在本机识别并匿名化文本、PDF、Word 文档和图片里的个人信息，用户可以把匿名化后的内容发给 AI 助手，再把 AI 的回复还原成真实信息。**完全在本机运行，不上传任何内容。** 完全免费，没有账号和付费功能。
- 已有 Android 版（Flutter），这是 Windows 版的功能基准。
- Windows 版的硬性要求（用户原话的意思）：
  1. **至少具备 Android 版的全部功能**（见第 5 节清单）。
  2. **使用同一套视觉设计和颜色**（见第 6 节）。
  3. **不能完全照搬 Android 的模式**：Windows 会覆盖更多功能，具体范围用户还没完全想好。所以架构要给扩展留余地，而不是把手机交互原样搬到桌面。

## 2. 仓库与依赖关系

| 仓库 | 本地路径 | 作用 | 当前 main |
|---|---|---|---|
| [docudis-core](https://github.com/stonetech-pxia/docudis-core) | `../docudis-core` | Rust 核心：规则、名单、词典、合并与重叠处理、匿名化、还原；`docudis_v1_*` C ABI；Dart 绑定 `bindings/dart`（包名 `docudis_ffi`） | `7244cd3` |
| [docudis-ner](https://github.com/stonetech-pxia/docudis-ner) | `../docudis-ner` | Rust NER：模型配置解析、分词、分窗、ONNX Runtime 推理、BIO 解码；`docudis_ner_v1_*` C ABI；Dart 绑定 `bindings/dart`（包名 `docudis_ner_ffi`）；模型 manifest、训练流程 | `66bd2c6` |
| [docudis-android](https://github.com/stonetech-pxia/docudis-android) | `../docudis-android` | Flutter App（Android/iOS）、旧的 Dart 参考引擎 `packages/docudis_engine`、PDF 处理包 `packages/docudis_pdf`、测试集和 benchmark | `7b02c4f` |
| docudis-windows | 本仓库 | Windows 版（空仓库） | — |

依赖方向是单向的，不能反过来：

```text
App（Android / Windows）
  ├─> docudis-core  （C ABI + Dart FFI）
  └─> docudis-ner   （C ABI + Dart FFI）──> docudis-core（只用它的 Detection 契约）

docudis-core：不依赖任何模型、平台或 UI
```

**分工**（用户确认过）：用哪个模型由 App 决定；推理由模型完成（代码在 docudis-ner）；推理结果怎么使用（合并、重叠处理、匿名化）由 core 决定。core 通过 v1 JSON 请求的 `detections` 字段接收**一个或多个**模型的结果（`source: "model"`，用 `detector` 区分模型）。

`../stonetech_app_kit` 是另一个产品用的登录/付费逻辑包，Docudis **不使用**。

## 3. 已经定下的决策

- **技术栈：Flutter Desktop。** 理由是能复用 Android 版的设计系统、多语言和大部分 UI 代码，并通过 Dart FFI 直接调用两个 Rust 库。（2026-10-01 讨论时推荐并写入了计划，用户没有反对；如果你发现有强烈的反对理由，先和用户确认，不要自行更换。）
- **独立仓库**：Windows 版在 docudis-windows，不放进 docudis-android 的 `windows/` 目录。
- **引擎全部走 Rust**：core 和 NER 都通过 C ABI 调用。**Windows 版不要依赖 `docudis_engine`（旧 Dart 引擎）**，它是迁移期的参考实现，会被删除（见 docudis-android 的 `docs/HANDOFF-rust-ner-2026-10-01.md` 阶段 3、4）。
- **两个原生库各自独立**：`docudis_capi.dll`（core）和 `docudis_ner_capi.dll`（NER），两者之间只通过 v1 JSON 交换检测结果。Dart 绑定在 Windows 上默认就按这两个文件名加载。
- **Windows 计划接入 OpenAI Privacy Filter 作为模型**（见第 7.3 节），可以单独使用，也可以和 XLM-R 同时使用。
- **ML Kit 只在手机上用**：Windows 上的 OCR、语言识别、实体识别都要换成别的方案（见第 5 节）。

## 4. 当前 Android 版的运行方式（理解现状用）

- **处理流程**（`lib/anonymize/anonymize_service.dart`）：提取文本 → 检测 → 匿名化 → 存储。
- **检测器**：
  - 用户词典
  - 正则规则（按检测到的语言选择地区规则包，在 isolate 里运行）
  - 内置的公司名、中文地名名单
  - NER
  - ML Kit 实体识别
- **NER**：默认通过 `RustNerDetector` 调用 docudis-ner（在后台 isolate 里推理）。Rust 加载失败时回退到 Dart 版；`--dart-define=DOCUDIS_DART_NER=true` 可以强制走 Dart。Rust 和 Dart 的输出在设备上逐位一致。
- **core**：生产路径**还是 Dart 旧引擎**。Rust core 只在 `--dart-define=DOCUDIS_RUST_DIFFERENTIAL=true` 时做差分对比。`reapply`（审阅页的切换）、审阅预览和还原都不经过 Rust。
- **原生库构建**：
  - `tool/prepare_docudis_{core,ner}.sh` 按 `tool/docudis_{core,ner}_version.json` 锁定的版本拉取源码，调用该仓库的 `scripts/build-android.sh`（cargo-ndk）。
  - Gradle 任务 `prepareDocudis{,Ner}{Debug,Release}Native` 负责把库打进 APK。
  - ONNX Runtime 来自 `onnxruntime-android` 1.30.0 自带的 `libonnxruntime.so`，按文件名加载。
- **模型**：
  - `tool/fetch_models.sh` 按锁定的 docudis-ner 版本，把 `model.json` 和模型文件写进 git 忽略的 `assets/models/`（需要登录 Hugging Face，`xlmr_ner_docudis` 是私有仓库）。
  - Android 用 Play Asset Delivery 打包；运行时由 `ModelLocator` 复制到 App 的 support 目录。

## 5. Android 功能清单 → Windows 对应方案

"状态"一列：**可直接复用**＝纯 Dart 或插件已支持 Windows；**需替换**＝依赖 Android/iOS 专属 API；**需决定**＝方案要和用户商量。

| 功能 | Android 实现（docudis-android 路径） | Windows 方案 | 状态 |
|---|---|---|---|
| 三个标签页：保护 / 历史 / 账户 | `lib/home/home_page.dart`、`ClayNavBar` | 桌面上可能更适合侧边栏，布局可调整，但视觉沿用 Clay | 需决定（布局） |
| 粘贴文本 | `ui/protect_page.dart`，`Clipboard.getData` | 同样可用 | 可直接复用 |
| 上传文档：txt、md、csv、pdf、docx、jpg、jpeg、png、webp、heic | `file_picker`；`input/text_extractor.dart:36` | `file_picker` 支持 Windows；桌面上应加**拖放** | 可直接复用，并扩展 |
| 照片识别：拍照或从相册选 | `image_picker` | Windows 没有相机入口，改为选图片文件、拖放，或从剪贴板粘贴截图 | 需替换 |
| OCR（图片、扫描版 PDF） | ML Kit 文字识别（中文和天城文脚本）；扫描页由 pdfrx 按 200 dpi 渲染后识别 | 二选一：Windows 自带的 `Windows.Media.Ocr`，或 PaddleOCR ONNX 经 Rust 调用（docudis-android 有 `tool/run_ppocrv6_benchmark.py` 可做对比）。图片涂黑依赖 OCR 返回的行和词坐标（`image_redaction.dart` 目前用的是 ML Kit 的 `TextLine`） | 需替换、需决定 |
| 语言识别（决定用哪些地区规则） | ML Kit 语言识别（`detectors/language_detector.dart`） | 建议放进 core：core 已有 `regions_for_languages`，但还没暴露在 ABI 里；语言识别可以用 Rust crate（如 `whatlang`、`lingua`） | 需替换 |
| ML Kit 实体识别 | `detectors/mlkit_entity_detector.dart` | 由 Privacy Filter 等模型替代 | 需替换 |
| NER | `model/rust_ner_detector.dart` + docudis-ner | 同样用 `docudis_ner_ffi`；ONNX Runtime 改用 `onnxruntime.dll` | 可复用，需改加载 |
| 系统分享接收、"打开方式" | `SharedInput.kt`、`shared_input.dart`、AndroidManifest | 文件关联、"打开方式"、命令行参数；可选资源管理器右键菜单和"发送到" | 需替换 |
| 文本选择菜单里的"匿名化"（原地替换） | `ProcessTextActivity.kt`、`process_text.dart` | 桌面对应：全局快捷键匿名化选中文本或剪贴板 | 需替换、需决定 |
| 快捷设置磁贴"匿名化剪贴板" | `AnonymizeClipboardTileService.kt` | 系统托盘菜单或全局快捷键 | 需替换、需决定 |
| 结果页：匿名化后 / 原文切换、复制、分享文件 | `ui/result_page.dart` | 复制可直接用；分享可用 `share_plus`（Windows 支持），桌面上更常见的是"另存为"或打开所在文件夹 | 基本可复用 |
| "发送到"AI 应用（11 个：ChatGPT、Claude、Gemini、Grok、Perplexity、DeepSeek、Copilot、Kimi、豆包、通义千问、Le Chat） | `ai_apps.dart`；Android 按包名检测并定向发送（`AiApps.kt`）；**非 Android/iOS 平台目前直接隐藏这一行** | 改为：复制到剪贴板后打开各家网页版（`url_launcher`），或检测已安装的桌面客户端 | 需替换 |
| 审阅页：点占位符显示原值、点普通文字手动遮盖；"隐藏所有金额/日期"开关 | `ui/review_page.dart`、`ui/highlights.dart`、`manual_blocks.dart` | UI 可复用；目前的重新生成走 Dart 旧引擎的 `DetectionPipeline.merge`、`anonymize`、`chunkText`，要换成 core 的 ABI（见第 7.1 节缺口） | 需改引擎调用 |
| 还原页：粘贴 AI 回复后还原，并检查回复是否属于这份文档 | `ui/restore_page.dart`，`ReplyMatcher`（Dart 旧引擎） | UI 可复用；`ReplyMatcher` 要搬进 core | 需改引擎调用 |
| 历史：列表、重命名、删除、全部删除 | `ui/history_page.dart`、`storage/record_store.dart` | 存储格式可沿用；Android 是**明文文件**，不加密，并排除在系统备份之外。Windows 上要决定是否加密（如 DPAPI）、放在哪个目录 | 需决定 |
| 词典：总是隐藏 / 从不隐藏、"只隐藏列表里的词"、从最近的操作里给出建议 | `lib/home/dictionary_page.dart`、`providers.dart` | 可复用 | 可直接复用 |
| 账户页：词典入口、语言选择、清除本机数据、隐私政策、联系邮箱、版本号 | `lib/home/account_page.dart` | 可复用（`url_launcher`、`package_info_plus` 都支持 Windows） | 可直接复用 |
| 设置项 | SharedPreferences 里只有 `app_locale` 和 `list_only` | 同样可用 | 可直接复用 |
| 多语言：en、es、fr、zh（`app_en.arb` 有 159 个 key） | `lib/l10n/` | 复用 ARB | 可直接复用 |
| PDF 匿名化输出 | `packages/docudis_pdf`（基于 pdfrx 的 PDFium，删除被遮盖的文字对象，其余文字按原字体重排；扫描页和无法编辑的页转成图片后加黑框；去掉元数据、书签和表单） | pdfrx 支持 Windows（`pdfium.dll` 由 native assets 提供；pdfrx README 说构建时需要开启 Windows **开发者模式**；DLL 怎么打包进安装包需要实测确认） | 可复用，需实测 |
| DOCX 匿名化输出 | `output/docx_redaction.dart`（纯 Dart） | 可复用 | 可直接复用 |
| 图片匿名化输出（黑框） | `image_redaction.dart` | 绘制逻辑可复用；坐标来源要从 ML Kit 换成新的 OCR | 需改 OCR 接口 |

各插件的 Windows 支持情况（在 pub-cache 里核对过）：
- **支持 Windows**：`file_picker`、`image_picker`（只能选文件，没有相机）、`share_plus`、`shared_preferences`、`path_provider`、`url_launcher`、`package_info_plus`、`pdfrx`。
- **纯 Dart**：`flutter_svg`、`archive`、`xml`、`flutter_riverpod`、`intl`。
- **只支持 Android/iOS**：三个 `google_mlkit_*`。
- **不需要**：`flutter_onnxruntime`。Windows 不需要 Dart 版推理。

Android 的平台 channel 在 Windows 上都需要替代或删除：
- `com.stonetech.docudis/model_assets`：读取模型文件。Windows 上直接从磁盘读取即可。
- `com.stonetech.docudis/ai_apps`
- `com.stonetech.docudis/shared_input`
- `com.stonetech.docudis/process_text`
- `paste_control`：只有 iOS 有。

## 6. 设计系统（"Clay"，必须保持一致）

唯一来源是 docudis-android 的 `lib/theme/clay_theme.dart` 和 `lib/theme/clay_widgets.dart`，设计说明在 `design/README.md`，选定的设计稿是 `design/mockups/DirectionClay.dc.html`。目前**只有浅色主题**。

- **颜色**：
  - 背景：bg `#F5EFE8`，surface `#FFFCF8`，blob `#EAD9C8`。
  - 主色 primary `#C8623A`，按下态 `#A84E2C`，浅色 tint `#F6DED5`。
  - 次色 secondary `#6B7F62`，tint `#E3E9DC`，文字 `#4E6644`。
  - 第三色 tertiary `#B8926A`，tint `#EFE3D2`。
  - 文字：ink `#2A2420`，muted `#6B5F55`，caption `#8A7B6F`，placeholder `#A89A8E`。
  - 分隔线 `#E8DFD4`，禁用 `#E6E2DD`。
  - 警告：背景 `#F3E8CB`，文字 `#7A5A10`；错误 `#B03A2E`。
- **实体颜色**：每种实体类型都有背景、文字、强调三色（`clay_theme.dart:117-173`），例如人名是 `#F6DED5` / `#8E3B22` / `#C8623A`，地址是 `#DCE8EA` / `#2E5C66` / `#4C8A96`。
- **字体**：标题用 Sora（可变字体，600/700），正文用 Karla（可变字体，400/500/700，含斜体），文件在 `assets/fonts/`，都是 OFL 许可。**每个文字样式都要同时设置 `fontVariations` 和 `fontWeight`**，否则所有字重都会显示成 Regular。`Clay.heading()`、`Clay.body()` 已经处理好了。占位符用等宽字体，回退顺序是 Roboto Mono、Menlo、Consolas。
- **形状与动效**：卡片圆角 22，控件圆角 16，图标块是 16/16/16 加左下角 6；按钮高 52，最小点击区 44；阴影 `0x1A785A3C`，模糊 30，y 偏移 10；动效 240 ms，easeInOutCubic。
- **组件**：ClayPage、ClayCard、ClayNavBar、ClaySegmented、ClayPill、ClayCountChip、ClayIconTile、ClaySuccessBanner、ClayWarningNote、ClayLockNote、ClayDocumentCard、ClayReveal、showClayProgressDialog 等。
- **图标与素材**：
  - App 图标在 `design/logo/`，启动图标背景色 `#C8623A`。
  - AI 应用图标在 `assets/ai_logos/`：11 个 SVG，来自 @lobehub/icons（MIT），商标归各自所有者。
- **截图对比测试（golden）**：基准图在 macOS 上生成，`test/flutter_test_config.dart` 只在 macOS 上比对像素。Windows 渲染出来的像素和基准图不同，所以 Windows 版如果要做截图对比测试，需要单独一套基准图，或者沿用"只在一个平台上比对像素"的策略。

## 7. 引擎、模型与原生库

### 7.1 用 core 作为生产路径，有几个缺口要先补

Android 的交接文件（`docs/HANDOFF-rust-ner-2026-10-01.md`）列出了 core 的 C ABI 目前缺少的能力。Windows 版不用旧引擎，所以这些都要在 **docudis-core** 里补齐。这件事和 Android 的阶段 3 是同一件事，做一次，两边共用：

- `chunkText` / `TextChunk`：审阅页把文本切成可点击的片段。
- `ReplyMatcher` / `ReplyCheck`：还原前检查 AI 回复是否属于这份文档。
- 按语言选择地区规则包：Rust 里有 `regions_for_languages`，但没有暴露在 ABI 里。
- 只合并、不重新检测（审阅页切换遮盖时用）：Rust 里有 `merge`，同样没有暴露。
- **Dart 侧的类型化模型**（Detection、DetectionSource、EntityType、AnonymizedText、PlaceholderMap、MappingEntry）：已决定放进 core 的 `bindings/dart`，两个 App 共用。

规则：新增 ABI 函数不能改变 `docudis_v1_*` 已有函数的行为；如果要做破坏性修改，就新开一个版本命名空间。core 的 offset 都是 UTF-8 字节，Dart 绑定会负责和 UTF-16 互相转换。

### 7.2 Windows 上的原生库

- **core**：`cargo build --release -p docudis-capi --target x86_64-pc-windows-msvc`，产物是 `docudis_capi.dll`。
- **NER**：`cargo build --release -p docudis-ner-capi --target x86_64-pc-windows-msvc`，产物是 `docudis_ner_capi.dll`。
- **ONNX Runtime**：用微软官方发布的 Windows 版 `onnxruntime.dll`，版本和 Android 对齐（1.30.x）。docudis-ner 用的是 `ort` 2.0.0-rc.13，在运行时加载 ONNX Runtime 库，加载时由调用方传入库的路径或文件名。以后如果要用 GPU（DirectML），可以再评估。
- 两个 Rust 仓库目前只有 Android 的构建脚本（`scripts/build-android.sh`）。Windows 的构建脚本（以及 CI 里的 `windows-latest` job）需要新增：可以加在各自的 Rust 仓库里，也可以按 Android 的做法，由 App 仓库按锁定版本拉取源码后再编译。版本锁定沿用 `tool/docudis_{core,ner}_version.json` 的做法，不要追踪会变的分支。
- 三个 DLL 要随 App 一起发布：可以通过 Flutter Windows 的 `windows/CMakeLists.txt` 安装规则，也可以用 native assets。
- `ort` rc.13 的两个已知限制（详见 docudis-ner 的 README）：
  - 同一个进程里，第一次加载 ONNX Runtime 失败后不能重试。docudis-ner 会直接返回第一次的错误，以避免 panic。
  - 命令行进程退出时可能在 ONNX Runtime 析构中崩溃。这是在 Android 上观察到的，Windows 上需要实测。

### 7.3 模型：OpenAI Privacy Filter

- 公开模型，Apache-2.0。总参数约 1.5B（MoE 结构，每次实际参与计算的约 50M），提供 ONNX 和多个量化版本，上下文长度 128k。
- 输出是 **BIOES 标签，用约束 Viterbi 解码**，覆盖 8 类信息：账号、地址、邮箱、人名、电话、URL、日期、secret。准确的标签名以模型配置为准。
- 需要在 **docudis-ner** 里做的事（2026-10-02 已全部完成，见 docudis-ner `6badf8e` 和它的 `models/README.md`；`account_number` 暂不映射）：
  - 实现 BIOES 和 Viterbi 解码（现在只有 BIO 加 argmax）。
  - 给 `ModelSpec`（`model.json`）加 `scheme` / `decoder` 之类的字段。
  - 确认它的 tokenizer 能用 HuggingFace `tokenizers` 加载。
  - 写 `models/<名字>/model.json`，并在 `manifest.json` 里登记下载来源和 SHA-256。
- 8 类都能映射到 core 已有的实体类型（account 可以映射到 `Id` 或 `Number`，secret 映射到 `Secret`），**core 不用改**。
- 和规则检测有重叠的部分（邮箱、电话、URL、账号），core 的优先级是"带校验的规则 > 模型"，由 core 统一处理。
- 模型体积大，打包和分发方式要和用户商量（见第 9 节）。

## 8. 开发环境与测试

- `flutter build windows` 只能在 Windows 上运行，需要 Visual Studio 的 C++ 桌面开发组件和 Rust 的 MSVC 工具链。pdfrx 需要开启开发者模式。用户有一台 Windows 机器（就是训练模型用的那台 GPU 机器），docudis-android 的 `docs/HANDOFF-macos-2026-09-23.md` 记录了这个项目早期在 Windows 上开发时的经验。
- 在 macOS 上可以开发和测试纯 Dart 逻辑、Rust 代码和大部分 UI，但没法产出 Windows 包，也没法在本机验证 Windows 专属的功能。
- 测试和数据资源都在 docudis-android：
  - `benchmark/`（测试集，同时也被 docudis-ner 的训练隔离检查引用，不要搬走）
  - `integration_test/`
  - core 和 NER 的一致性测试套件
  - 设备上的 Rust/Dart NER 一致性测试（`integration_test/docudis_ner_ffi_test.dart`），可以作为 Windows 版 NER 的验收参考。
- CI 建议用 `windows-latest`，跑 analyze、单元测试、`flutter build windows`，并检查三个 DLL 都在产物里。集成测试用 `flutter test -d windows integration_test/...`。

## 9. 尚未决定、需要先问用户的事

1. **Windows 新增功能的范围**（用户还没想好）。在问之前，可以先整理一份候选清单供用户挑选，比如：批量处理多个文件或整个文件夹、拖放、全局快捷键、托盘常驻、剪贴板监听、资源管理器右键菜单、多窗口并排审阅、更多文件格式（xlsx、pptx、eml、msg 等）、离线 AI 对话集成。**清单只是选项，不是承诺。**
2. **UI 代码怎么和 Android 共享**：
   - 复制一份：简单，但两边会逐渐走样。
   - 把设计系统（主题、组件、字体、l10n）抽成共享的 Flutter 包，两个 App 按 git 版本引用：推荐，但需要改动 docudis-android。
   - 更进一步，把页面也一起共享。
3. **OCR 方案**：`Windows.Media.Ocr` 还是 PaddleOCR ONNX。
4. **模型组合**：只用 Privacy Filter，还是同时用 XLM-R。另外，App 里是否让用户选择或开关模型（Android 现在是写死的）。
5. **模型分发**：打进安装包，还是首次运行时下载（Privacy Filter 体积大；xlmr_ner_docudis 在私有的 Hugging Face 仓库里）。
6. **打包和发布**：MSIX / Microsoft Store、安装程序，还是绿色版；自动更新；代码签名。
7. **本地记录是否加密**（Android 目前是明文），以及存储位置。
8. 支持的最低 Windows 版本，是否支持 Windows on ARM（arm64）。
9. **桌面布局**：底部导航还是侧边栏；窗口尺寸和响应式规则。设计稿只有手机尺寸。

## 10. 建议的起步顺序（和用户确认后再执行）

1. 搭建 Flutter Windows 工程骨架：Clay 主题、字体、l10n、三个页面的空壳，按第 9 节第 2 条的结论决定是复制还是引用共享包。
2. 在 Windows 上编译并加载 `docudis_capi.dll`、`docudis_ner_capi.dll`、`onnxruntime.dll`，用 Dart FFI 跑通 core 和 NER 的 ABI 版本检查和一次检测（可以先用 xlmr_ner_docudis 验证整条链路）。
3. 在 docudis-core 里补齐第 7.1 节的缺口，让粘贴文本 → 审阅 → 结果 → 还原这条主流程完全走 Rust。
4. 文件输入和输出：txt、docx、PDF（pdfrx）、图片（先定 OCR 方案）。
5. 在 docudis-ner 里实现 Privacy Filter（BIOES 和 Viterbi），并在 Windows 上接入。
6. 补齐剩下的 Android 功能（历史、词典、账户、"发送到"等），再开始做 Windows 新增的功能。

## 11. 工作约定（沿用前几个仓库）

- 每次开始前，先检查涉及的各仓库的 `git status` 和 `git log`。不要使用 `git reset --hard`、强推或其他会丢失工作的命令。推送、合并和创建 PR 要按用户的授权来。
- 依赖的其他仓库一律按 commit 锁定，不能依赖开发机上的绝对路径。
- 日志里不能出现原文、检测到的值或映射，只记录长度、类型、offset、错误码，或者不可逆的摘要。
- 每份数据只有一个可编辑的来源：规则和名单在 docudis-core，模型配置和 manifest 在 docudis-ner，测试集在 docudis-android。
- 没有实际执行过的验证，不能写成"已通过"。
- 用户偏好用中文、**大白话**讲清楚取舍的前因后果；需要用户做选择时，先解释背景，再给建议。

## 12. 推荐阅读

- docudis-android：
  - `README.md`
  - `docs/anonymization-design.md`（产品和引擎的权威决策，和设计稿冲突时以它为准）
  - `docs/HANDOFF-rust-ner-2026-10-01.md`（Rust 迁移的阶段计划和进度）
  - `docs/rule-classification.md`
  - `design/README.md`
  - `docs/HANDOFF-macos-2026-09-23.md`（Windows 时期的环境经验）
- docudis-core：`README.md`、`crates/README.md`、`crates/docudis-capi/include/docudis.h`
- docudis-ner：`README.md`（包括 ONNX Runtime 的说明）、`crates/docudis-ner-capi/include/docudis_ner.h`、`models/README.md`
