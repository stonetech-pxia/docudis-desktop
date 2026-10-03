# 不联网、不上传：说明与验证

Docudis 在本机处理文档，不把任何内容发出去。这一页写清楚这句话具体指什么、由什么保证，以及怎样自己验证。macOS 部分已经完成；Windows 的测试和说明待补充。

## 具体承诺

- 识别、匿名化、还原和 NER 模型推理全部在本机运行，处理过程中不发任何网络请求。
- 没有账户、统计、崩溃上报，也不自动检查更新。
- App 唯一会触发联网的地方：在设置里点"隐私政策"等链接时，用系统浏览器打开网页。
- 第三方组件的遥测已关闭，包括 ONNX Runtime 内置的遥测（见下文"发现并修复的问题"）。

数据存放在本机：

- 记录（原文、匿名化结果、还原用的对照表，以及导入的文件副本）在 App 的数据目录下的 `records/`，**明文保存**。设置里可以打开这个文件夹，也可以一键清除本机数据。
- macOS 上的数据目录在 App 的沙盒容器里：`~/Library/Containers/com.stonetech.docudis/Data/Library/Application Support/com.stonetech.docudis/`。

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

待补充：测试方法和结果。
