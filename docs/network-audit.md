# 不联网、不上传：说明与验证

Docudis 在本机处理文档，不把任何内容发出去。这一页写清楚这句话具体指什么、由什么保证，以及怎样自己验证。macOS 和 Windows 分开写，因为两边由什么保证、ONNX Runtime 的遥测怎么发出都不一样。

## 具体承诺

- 识别、匿名化、还原和 NER 模型推理全部在本机运行，处理过程中不发任何网络请求。
- 没有账户、统计、崩溃上报，也不自动检查更新。
- App 唯一会触发联网的地方：在设置里点"隐私政策"等链接时，用系统浏览器打开网页。
- 第三方组件的遥测已关闭，包括 ONNX Runtime 内置的遥测（见下文两个平台各自的"发现并修复的问题"）。

数据存放在本机：

- 记录（原文、匿名化结果、还原用的对照表，以及导入的文件副本）在 App 的数据目录下的 `records/`，**明文保存**。设置里可以打开这个文件夹，也可以一键清除本机数据。
- macOS 上的数据目录在 App 的沙盒容器里：`~/Library/Containers/com.stonetech.docudis/Data/Library/Application Support/com.stonetech.docudis/`。
- Windows 上的数据目录是 `%APPDATA%\stonetech\Docudis\`。

## macOS

### 由系统强制：App 沙盒

Release 版开着 App 沙盒，并且**没有任何联网权限**（没有 `com.apple.security.network.client`，也没有 `network.server`）。在这种配置下，macOS 内核会拒绝 App 发起的网络连接，App 里的第三方库也一样。沙盒还限制 App 只能读写用户自己打开、拖进来或另存为的文件，以及它自己的容器。

权限列表写在签名里，改动就会让签名失效。任何人都可以核对：

```bash
codesign -d --entitlements - /Applications/Docudis.app
```

结果里应该有 `com.apple.security.app-sandbox`，并且没有 `com.apple.security.network.client`。

沙盒管不到借用其他进程发出的请求，比如让系统浏览器打开一个网址。App 里唯一这样做的是设置页的链接，而且浏览器会弹出来，用户看得见。

### 原生库导入了哪些网络函数

用 `nm -u` 查看 App 打包的原生库导入了哪些网络相关的函数：

| 库 | 网络相关的导入 |
|---|---|
| libdocudis_capi（docudis-core） | 无 |
| libdocudis_ner_capi（docudis-ner） | 无 |
| PDFium | 无 |
| FlutterMacOS | `socket`、`connect`、`getaddrinfo` 等：这是 Dart `dart:io` 自带的，只说明有联网能力 |
| libonnxruntime | `NSURLSession`、网络状态监听：用于它内置的遥测，见下文 |

两个 Rust 库和 PDFium 根本不导入网络函数，所以它们本身发不出数据。其余部分靠下面的动态审计来检查。

### 动态审计

脚本是 [tool/network_audit_macos.sh](../tool/network_audit_macos.sh)，需要 sudo（tcpdump 要用）。它在下面两段使用过程中，记录 Docudis 进程的一切网络活动：

1. Release 版打开一段时间（`IDLE_SECONDS`，这期间也可以手动操作）。
2. 跑一遍完整的集成测试 `integration_test/flow_test.dart`：粘贴 → 匿名化 → 审阅 → 还原、词典、PDF、Word，用的是真实的原生库和模型。这是 Debug 版，需要和 flutter 工具在 127.0.0.1 上通信，所以本机回环的包单独计数。

检查的项目：

| 检查 | 方法 | 通过条件 |
|---|---|---|
| 离开本机的包 | `tcpdump -i pktap`：内核给每个包标上所属进程，只保留 Docudis 的 | 0 |
| DNS 查询 | 域名查询由系统的 mDNSResponder 代为发出，它的日志会标明是替哪个进程查的 | 0 |
| 被沙盒拦下的联网尝试 | 被拦下的尝试不会产生网络包，但会记进沙盒日志 | 0 |
| ONNX Runtime 遥测文件 | 运行期间是否写入了 `.onnxruntime/` 目录 | 0 |
| 抓包丢失 | tcpdump 报告的内核丢包数，丢了包就说明结果可能不完整 | 0 |

运行：

```bash
tool/network_audit_macos.sh
```

```bash
APP=/Applications/Docudis.app FLOW=0 IDLE_SECONDS=86400 tool/network_audit_macos.sh
```

第一条从源码编译 Release 版再测；第二条测已安装的 App，跳过集成测试，打开 24 小时。结果写在 `build/network_audit/<时间>/`，其中有原始抓包文件（pcapng）和各项日志。任何一项不为 0，脚本的退出码就是 1。

### 结果

2026-10-03，macOS 27.0（Apple 芯片），docudis-ner `b18d618`，ONNX Runtime 1.30.0，Release 版开着沙盒、没有联网权限：

| 检查 | 结果 |
|---|---|
| 离开本机的包 | 0 |
| DNS 查询 | 0 |
| 被沙盒拦下的联网尝试 | 0 |
| ONNX Runtime 遥测文件 | 0 |
| 抓包丢失 | 0 |
| 集成测试 | 3 项全部通过 |

本机回环共 1332 个包，全部属于集成测试的 Debug 版进程，也就是它和 flutter 工具在 127.0.0.1 上的通信。Release 版一个包也没有。

这次 Release 版只打开了 60 秒，期间没有手动操作；在全新系统上长时间打开的测试还没做。

### 发现并修复的问题：ONNX Runtime 遥测

第一次完整审计时，脚本发现 Docudis 在反复查询同一个域名，间隔越来越长（退避重试）。原因是 ONNX Runtime 官方 macOS 版内置了微软的 1DS 遥测：每次加载模型，它都会在 `Application Support/Microsoft/DeveloperTools/.onnxruntime/` 下保存一个持久的设备 ID 和一个事件队列，然后尝试上传。

- 事件内容是机型、CPU、内存、macOS 版本、App 名称、ONNX Runtime 版本和设备 ID，**不包含文档内容**。
- docudis-ner 原本已经调用 `with_telemetry(false)` 关闭遥测，但这一步发生在环境创建之后，而遥测在创建环境时就已经启动了。
- 开着沙盒时连接被拦下，没有数据离开本机，但 DNS 查询仍然发出去了。修复之前，没开沙盒的开发版本可以联网，很可能已经把这些事件上传给了微软（已上传的事件会从队列里删除，所以无法事后确认）。

修复：docudis-ner 在加载 ONNX Runtime 之前设置环境变量 `ORT_DISABLE_TELEMETRY=1`，这样遥测根本不会启动，也不会写任何文件。审计脚本也加上了对遥测文件的检查。

## Windows

### 没有系统级的强制

Windows 版以解压即用的 zip 发布，是普通的桌面程序，没有 macOS 那样由系统拦下联网的沙盒。所以 Windows 上靠两层检查：静态检查保证代码和依赖里没有联网的部分，运行中的检查确认实际没有连接。想要系统再拦一道的用户，可以自己加一条防火墙规则（见下文）。ONNX Runtime 那种由系统服务代为上传的遥测，沙盒和防火墙都拦不住，靠自己编译 ONNX Runtime 解决。

### 用防火墙再加一道保险（可选）

在管理员 PowerShell 里运行，把路径换成解压后 `docudis.exe` 的完整路径。Windows 防火墙里"阻止"规则优先于"允许"规则，加上后 `docudis.exe` 发出的任何连接都会被系统拦下；设置页打开的链接由浏览器负责，不受影响。

```powershell
New-NetFirewallRule -DisplayName "Docudis - block outbound" -Direction Outbound -Action Block -Program "C:\Tools\Docudis\docudis.exe"
```

核对和删除：

```powershell
Get-NetFirewallRule -DisplayName "Docudis - block outbound" | Get-NetFirewallApplicationFilter
```

```powershell
Remove-NetFirewallRule -DisplayName "Docudis - block outbound"
```

规则按路径生效：把文件夹挪到别处，要按新路径重新加。它只在 Windows Defender 防火墙开着时有效。

### 下载后核对

发布页给出 zip 的 SHA-256（打包时生成的 `.sha256` 文件），下载后用 `Get-FileHash` 核对。zip 由 [tool/package_windows.ps1](../tool/package_windows.ps1) 从源码构建，任何人都可以按 README 自己构建一份。

### 静态检查

[test/offline_test.dart](../test/offline_test.dart)，每次 `flutter test` 都会运行：

| 检查 | 方法 | 允许的例外 |
|---|---|---|
| App 自己的代码 | 扫描 `lib/` 和 `packages/docudis_pdf/lib`，找联网 API（`HttpClient`、`Socket`、`WebSocket`、域名解析等），以及把网址交给别的程序的调用（`launchUrl`、`openUri`） | 设置页用浏览器打开链接 |
| Dart 依赖 | 扫描所有依赖包的代码，含联网代码的包必须在审查名单里，并写明为什么没问题 | 例如 `http`：只在 pdfrx 用网址打开 PDF 时用到，App 只打开本地文件；`pdfium_dart` 只在构建时下载 PDFium |
| Rust 依赖 | 两个原生库的 `Cargo.lock` 里不能有 reqwest、hyper、rustls 等网络库 | 无 |
| DLL 和 exe 导入的系统库 | 直接读 PE 文件的导入表（含延迟加载），不能导入 `ws2_32`、`winhttp`、`wininet` 等网络库 | `flutter_windows.dll` |
| 微软遥测组 | 打包的文件不能把 ETW 事件登记在微软的遥测组里（见下文） | 无 |

每项检查都做过反向验证：故意放进一个违规项，确认检查会失败。

打包的文件导入了哪些网络相关的系统库：

| 文件 | 网络相关的导入 |
|---|---|
| docudis_capi.dll（docudis-core） | 无 |
| docudis_ner_capi.dll（docudis-ner） | 无 |
| onnxruntime.dll | 无 |
| pdfium.dll | 无 |
| 插件（desktop_drop、url_launcher、dartjni）和 docudis.exe | 无 |
| flutter_windows.dll | `ws2_32`、`iphlpapi`：这是 Dart `dart:io` 自带的，只说明有联网能力；第一项检查保证 App 的代码不用它 |

### 运行中的检查

集成测试 [integration_test/flow_test.dart](../integration_test/flow_test.dart) 在 Windows 上运行时，一个后台线程每隔几毫秒读一次系统的 TCP 和 UDP 连接表（`GetExtendedTcpTable`、`GetExtendedUdpTable`），记下 App 进程拥有的每个连接，覆盖粘贴 → 匿名化 → 审阅 → 还原、词典、PDF、Word 的整个流程，用的是真实的原生库和模型。测试开始前就已经在本机回环上监听的端口是 Dart 的调试服务，测试工具通过它控制 App，这部分不算。

```powershell
flutter test integration_test/flow_test.dart -d windows
```

局限：

- 两次读取之间开了又关的连接可能漏掉。读取足够频繁，任何要等网络回应的连接都会被看到。对照测试里故意打开一个 UDP 端口、连一个不会回应的地址，两者都被抓到了。
- 只看 App 自己的进程。借系统服务发出的数据（比如下文的 ETW 遥测）看不到，这类靠静态检查。
- 测的是 Debug 版。

### 结果

2026-10-03，Windows 11（10.0.26200，x64），docudis-ner `b18d618`，ONNX Runtime 1.30.0（从源码编译，不带遥测）：

| 检查 | 结果 |
|---|---|
| 静态检查 | 5 项全部通过 |
| App 进程打开的连接 | 0 |
| 集成测试 | 3 项全部通过 |

### 发现并修复的问题：ONNX Runtime 遥测

Windows 上的情况和 macOS 不一样：

- 官方 Windows 版的 ONNX Runtime 自己不联网：不导入网络库，也没有上传地址。它把事件写进 Windows 的事件系统（ETW），并把事件来源登记在微软的遥测组里。是否上传、什么时候上传，由 Windows 的诊断服务（DiagTrack）按用户的诊断数据设置决定。
- 用 ETW 录制实测：Docudis 每次创建 ONNX Runtime 环境时写出 4 条事件：ProcessInfo（ONNX Runtime 版本、CPU 型号、核心数、内存大小、是否挂着调试器）、DriverInfo（显卡型号和驱动版本），以及加载 CPU 计算模块的开始和结果。**不包含文档内容**。按事件上的标记，它们属于"可选诊断数据"。
- `with_telemetry(false)` 关不掉这 4 条：它们在创建环境时就写出了，早于关闭。之后的事件（比如创建会话）确实没再出现。
- `ORT_DISABLE_TELEMETRY` 在 Windows 上无效：Windows 版里根本没有这个变量。用 Python 版 ONNX Runtime 对照，设和不设写出的事件一样。
- 运行中的检查和沙盒都拦不住：上传的是系统服务，不是 App 进程。

修复：Windows 上的 `onnxruntime.dll` 改为从官方源码编译（锁定 v1.30.0 的 commit），加 `--no_telemetry`，见 [tool/prepare_native.ps1](../tool/prepare_native.ps1)。这样编出来的版本仍然会写事件，但不再登记在遥测组里，Windows 的诊断服务不会收集它们。

- 遥测组的标记在官方 DLL 里有 1 处，自己编译的版本里 0 处。静态检查的"微软遥测组"一项保证以后不会换回官方版。
- 用 docudis-android 的 201 段测试文本对比 NER 结果：官方版和自己编译的版本得出的 3612 处识别（含置信度）完全一致。
