# Bluetooth Compatibility Matrix for Flutter

This document outlines the Bluetooth Low Energy (BLE) support across different platforms in Flutter, based on the current ecosystem of available 3rd-party plugins and confirmed testing outcomes.

---

--

## ✅  Bluetooth suuport with 3rd-Party Libraries

| Library / Package | Description                                       | Supported Platforms                   |
|-------------------|---------------------------------------------------|----------------------------------------|
| `flutter_blue`    | Cross-platform BLE support (scan/connect/etc)     | Android, iOS, 🟡 macOS (partial)       |
| `flutter_reactive_ble` | Reactive BLE library with stream support     | Android, iOS                          |
| `win_ble`         | Basic BLE support using Windows UWP API           | Windows                                |
| `dbus`            | Dart D-Bus client for native Linux BlueZ access   | Linux                                  |
| `flutter_rust_bridge` | Rust interop layer to create native extensions | All native platforms                   |
| `dart:ffi`        | Dart foreign function interface for native calls  | All native platforms                   |
| `dart:js` / `package:js` | JavaScript interop for Web Bluetooth       | Web                                    |








-

## 🔧 Notes on Platform-Specific Support

### Android
- Stable, mature, and widely used.
- Full support for scanning, connecting, reading/writing, notifications.

### iOS
- Fully supported, but requires correct setup:
  - `NSBluetoothAlwaysUsageDescription` in `Info.plist`.
  - Handle permission prompts and iOS-specific behaviors.

### macOS
- CoreBluetooth is available on macOS.
- `flutter_blue` offers partial support, but for advanced BLE features or stability:
  - Extend plugin in Swift/Objective-C via platform channels.

### Windows
- BLE support via WinRT (`Windows.Devices.Bluetooth` namespace).
- Use `win_ble` for simple use cases.
- For advanced use (e.g., mesh or GATT services): consider FFI with C++ or Rust.

### Linux
- No official support.
- Implement scanning and connection with:
  - BlueZ via D-Bus (via `dbus` Dart package),
  - CLI commands (`bluetoothctl`, `hcitool`) wrapped in Dart,
  - FFI bindings to `libbluetooth` or using `flutter_rust_bridge`.

### Web
- Flutter Web doesn’t natively support Bluetooth.
- Browsers (like Chrome) provide the [Web Bluetooth API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Bluetooth_API).
- You can build support with:
  - Custom JavaScript interop using `dart:js`
  - Implementing a Flutter plugin that wraps JS APIs


---

## 🧩 Integration Strategy Suggestion for Multi-Platform BLE

1. **Abstract** BLE calls in a common Dart interface.
2. Use **platform-specific implementations**:
   - Android/iOS via `flutter_blue` or `flutter_reactive_ble`
   - macOS/Windows/Linux via plugins or FFI/native interop
3. Organize code as a **federated plugin** if you want to share your BLE logic:
   ```bash
   /lib/ble/
     ├── ble_interface.dart
     ├── ble_android.dart
     ├── ble_ios.dart
     ├── ble_macos.dart
     ├── ble_windows.dart
     └── ble_linux.dart






## Flutter native Summary Table

| Platform   | BLE Support     | Notes                                                                 | Recommended Libraries / Plugins                         |
|------------|------------------|-----------------------------------------------------------------------|----------------------------------------------------------|
| **Android**| ✅ Full          | Fully supported by mature plugins.                                   | [`flutter_blue`](https://pub.dev/packages/flutter_blue), [`flutter_reactive_ble`](https://pub.dev/packages/flutter_reactive_ble) |
| **iOS**    | ✅ Full          | Well-supported. Requires permissions in `Info.plist`.                 | [`flutter_blue`](https://pub.dev/packages/flutter_blue), [`flutter_reactive_ble`](https://pub.dev/packages/flutter_reactive_ble) |
| **macOS**  | 🟡 Partial       | CoreBluetooth works. Plugin may require patching.                     | [`flutter_blue`](https://pub.dev/packages/flutter_blue) (partial), custom Swift plugin via platform channels |
| **Windows**| 🟡 Partial       | BLE works via UWP. Plugin available, but limited features.            | [`win_ble`](https://pub.dev/packages/win_ble), custom FFI (C++/WinRT) |
| **Linux**  | 🔴 Minimal       | No official plugin. Requires custom FFI or DBus/BlueZ integration.    | [`dbus`](https://pub.dev/packages/dbus), native FFI, `flutter_rust_bridge` |
| **Web**    | 🔴 Not Supported | Web Bluetooth available only through JavaScript interop.              | N/A – requires `dart:js` and Web Bluetooth API            |