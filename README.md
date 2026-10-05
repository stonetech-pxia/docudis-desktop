# Docudis Desktop

English · [中文](README.zh-CN.md)

Docudis masks the personal details in a document before you paste it into an AI assistant, then puts them back into the assistant's reply. It runs entirely on your computer and never connects to the internet.

It finds names, addresses, dates, email addresses, phone numbers, IBANs, card numbers and national ID numbers in text, Word (.docx) and PDF files, replaces them with labels such as `[PERSON_1]`, and keeps the table that maps each label back to the original on your computer. Detection combines the rules of [docudis-core](https://github.com/stonetech-pxia/docudis-core) with an on-device name-recognition model from [docudis-ner](https://github.com/stonetech-pxia/docudis-ner).

This is the app for Windows (and macOS, from source for now). The phone app is [docudis-android](https://github.com/stonetech-pxia/docudis-android). Website: [docudis.com](https://docudis.com).

## Install on Windows

1. Download `docudis-<version>-windows-x64.zip` from [Releases](https://github.com/stonetech-pxia/docudis-desktop/releases/latest).
2. Check it: its SHA-256 must match the one on the release page (`Get-FileHash docudis-<version>-windows-x64.zip`). With the GitHub CLI you can also check that GitHub Actions built it from this repository:

   ```
   gh attestation verify docudis-<version>-windows-x64.zip -R stonetech-pxia/docudis-desktop
   ```

3. Unpack it anywhere and run `docudis.exe`. There is no installer, no administrator right is needed and no system setting is changed.
4. The app is not code signed yet ([why, and what is planned](docs/code-signing-policy.md)), so Windows may say "Windows protected your PC" the first time: click "More info", then "Run anyway".

Requires Windows 10 or 11, x64. Interface in English, French, Spanish and Chinese.

## What it does

- **Workspace:** paste, type or drop a file; Docudis shows the original, the masked text and the list of what it found. Click a finding, or any text, to mask or unmask it.
- **Files:** .txt, .md, .csv, .docx and PDFs that contain text. Word and PDF files also get a masked copy you can save. Scanned pages and images are not supported yet; a PDF with a scanned page gives text only, so no page leaves unmasked.
- **Restore:** paste the AI assistant's reply and Docudis puts the original details back, after checking that the reply belongs to that document.
- **History:** your latest 100 documents, kept on your computer.
- **Lists:** "Always hide" and "Never hide", for names Docudis should always mask or always leave alone.

Detection is automatic and can miss details or mask too much. Always review the result before you share it.

## Privacy

- No network connection, no account, no analytics, no crash reports, no update check. The only exception is a link you click in Settings, which opens in your browser.
- How that is enforced and checked, with the results: [docs/network-audit.md](docs/network-audit.md) (in Chinese for now). On macOS the app runs in Apple's sandbox without network access. On Windows, you can also [block it in the firewall](docs/network-audit.md#用防火墙再加一道保险可选):

  ```powershell
  New-NetFirewallRule -DisplayName "Docudis - block outbound" -Direction Outbound -Action Block -Program "C:\Path\To\docudis.exe"
  ```

- Your documents, lists and settings are stored **unencrypted** in `%APPDATA%\stonetech\Docudis\`. "Clear data on this device" in Settings deletes the documents. Full-disk encryption (BitLocker) is recommended.
- The masked text is pseudonymised, not anonymous: the table on your computer can restore it.
- [Privacy policy](https://docudis.com/privacy/desktop/)

### Uninstall

1. Quit Docudis and delete the unpacked folder.
2. Delete `%APPDATA%\stonetech\Docudis\` (documents, lists, settings, models you installed).
3. If you added the firewall rule, remove it from an administrator PowerShell: `Remove-NetFirewallRule -DisplayName "Docudis - block outbound"`.

## Using Docudis at work

Using Docudis unmodified inside your company, on any number of computers, puts no obligation on you under the AGPL. For IT teams, DPOs and legal teams: [docs/entreprise.md](docs/entreprise.md) (in French) covers what is stored where, the network checks, GDPR and the license.

## Build from source

The app is Flutter 3.47 (Dart 3.13, Riverpod 3). The detection engine (docudis-core) and the name recognition (docudis-ner) are Rust libraries called through a C ABI, pinned in [tool/native.lock.json](tool/native.lock.json).

**Windows x64:** Visual Studio with "Desktop development with C++" (including CMake), the Rust MSVC toolchain, Python 3, and Developer Mode turned on in Windows settings.

```powershell
powershell -ExecutionPolicy Bypass -File tool\prepare_native.ps1
```

```powershell
flutter run -d windows
```

`prepare_native.ps1` builds docudis-core, docudis-ner and ONNX Runtime (from source, without telemetry) into `build\native\windows\`. To package the zip, see [tool/package_windows.ps1](tool/package_windows.ps1).

**macOS (Apple silicon):**

```bash
tool/prepare_native.sh
```

```bash
flutter run -d macos
```

```bash
tool/fetch_models.sh
```

Run `fetch_models.sh` after the app has opened once, so that macOS has created its container. Without a model the app still works, with rules and word lists only.

**Tests:**

```bash
flutter test
```

```bash
flutter test integration_test/flow_test.dart -d windows
```

The integration test runs the whole flow (paste, mask, review, restore, lists, PDF, Word) with the real native libraries and model; on Windows it also records every network connection the app opens. More detail, in Chinese: [README.zh-CN.md](README.zh-CN.md).

## License

[GNU AGPL-3.0](LICENSE), Copyright 2026 Pengda Xia (stonetech); see [NOTICE](NOTICE). The bundled docudis-core and docudis-ner libraries are Apache-2.0. Settings > Open-source licenses lists every third-party component and its license.

## Security and contributing

Report security problems privately: [SECURITY.md](SECURITY.md). Issues are welcome, but never put real personal data in them. This repository does not accept pull requests for now; see [CONTRIBUTING.md](CONTRIBUTING.md).
