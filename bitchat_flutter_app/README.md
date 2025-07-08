# bitchat Flutter App

This is a Flutter implementation of bitchat - a secure, decentralized, peer-to-peer messaging app that works over Bluetooth mesh networks.

## Status: Early Development

This Flutter version is in early development and implements basic functionality:

- ✅ Flutter project structure scaffolding
- ✅ Binary protocol implementation (Dart port from Swift)
- ✅ Basic Bluetooth LE mesh service using flutter_blue_plus
- ✅ Message models and chat view model
- ✅ Basic terminal-style chat UI
- ✅ Device discovery and peer management
- ✅ Basic command system (/who, /join, /help, etc.)

## Missing Features (TODO)

- [ ] Full BLE advertising implementation (requires platform channels)
- [ ] Message encryption (X25519 + AES-256-GCM)
- [ ] Message relay/forwarding logic
- [ ] Channel management and password protection
- [ ] Proper error handling and edge cases
- [ ] Battery optimization features
- [ ] Message compression
- [ ] Persistent storage
- [ ] Advanced UI features

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Android Studio or Xcode for mobile development
- Physical device with Bluetooth LE support (required for testing)

### Installation

1. Install dependencies:
```bash
cd bitchat_flutter_app
flutter pub get
```

2. Run on device:
```bash
flutter run
```

### Permissions

The app requires Bluetooth permissions:
- **Android**: Location permission (required for BLE scanning)
- **iOS**: Bluetooth usage permissions

### Basic Usage

1. Launch the app on multiple devices
2. The app will automatically start scanning for nearby peers
3. Connected peers will appear in the peer list (tap the people icon)
4. Send messages in the main chat area
5. Use commands like:
   - `/who` - Show connected peers
   - `/join #channel` - Join a channel
   - `/help` - Show all commands

## Architecture

### Core Components

- **BitchatPacket**: Binary message packet format
- **BinaryProtocol**: Encoder/decoder for efficient BLE communication
- **BluetoothMeshService**: BLE mesh networking implementation
- **ChatViewModel**: Main app state management
- **HomeScreen**: Terminal-style chat interface

### Protocol Compatibility

This Flutter implementation maintains binary protocol compatibility with the original Swift version, enabling cross-platform communication between iOS/macOS and Android/Linux devices.

## Development Notes

### Known Limitations

1. **BLE Advertising**: Full peripheral mode advertising requires platform-specific implementation
2. **Background Processing**: Limited background BLE capabilities on mobile platforms
3. **Range**: Bluetooth LE range is typically 10-50 meters depending on environment

### Testing

Since this is a peer-to-peer mesh network app, testing requires:
- Multiple physical devices with Bluetooth LE
- Devices within Bluetooth range of each other
- Bluetooth permissions granted on all devices

### Contributing

This is an early implementation focusing on basic functionality. Key areas for improvement:
- Complete BLE advertising implementation
- Add encryption layer
- Improve error handling
- Optimize battery usage
- Add comprehensive testing

## License

This project is released into the public domain. See the LICENSE file for details.