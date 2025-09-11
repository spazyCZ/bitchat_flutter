# bitchat Flutter - Linux Ubuntu Setup Guide

This guide will help you set up bitchat Flutter on Ubuntu Linux with full Bluetooth Low Energy support.

## Quick Installation

Run the automated installation script:

```bash
git clone https://github.com/spazyCZ/bitchat_flutter.git
cd bitchat_flutter
chmod +x install_ubuntu.sh
./install_ubuntu.sh
```

**Important:** You must reboot your system after installation for Bluetooth permissions to take effect.

## What the Installation Script Does

1. **System Dependencies**: Installs required packages including:
   - CMake, Clang, Ninja build tools
   - GTK3 development libraries
   - BlueZ Bluetooth stack
   - Flutter development tools

2. **Flutter Setup**: 
   - Installs Flutter via snap (or manual download if snap fails)
   - Enables Linux desktop support
   - Configures the development environment

3. **Bluetooth Configuration**:
   - Enables Bluetooth service
   - Adds user to bluetooth group
   - Unblocks Bluetooth if needed
   - Sets up proper permissions

## Manual Installation Steps

If you prefer to install manually:

### 1. Install System Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa \
    clang cmake ninja-build pkg-config \
    libgtk-3-dev libbluetooth-dev bluez bluez-tools rfkill
```

### 2. Install Flutter

```bash
sudo snap install flutter --classic
# OR manual installation:
# curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.4-stable.tar.xz -o flutter.tar.xz
# sudo tar xf flutter.tar.xz -C /opt/
# echo 'export PATH="/opt/flutter/bin:$PATH"' >> ~/.bashrc
```

### 3. Enable Linux Desktop Support

```bash
flutter config --enable-linux-desktop
```

### 4. Configure Bluetooth

```bash
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
sudo usermod -a -G bluetooth $USER
sudo rfkill unblock bluetooth
```

### 5. Install Project Dependencies

```bash
cd bitchat_flutter
flutter pub get
```

### 6. Reboot and Test

```bash
sudo reboot
# After reboot:
flutter doctor
flutter devices  # Should show Linux (desktop)
```

## Running the App

### Basic BLE Scanner

The root project provides a basic BLE scanner for testing:

```bash
flutter run -d linux
```

### Full bitchat App

For the complete bitchat functionality:

```bash
cd bitchat_flutter_app
flutter pub get
flutter run -d linux
```

## Troubleshooting

### Bluetooth Issues

Check if Bluetooth is working:
```bash
systemctl status bluetooth
rfkill list bluetooth
bluetoothctl scan on
```

### Flutter Issues

Verify Flutter setup:
```bash
flutter doctor
flutter devices
```

### Permission Issues

Ensure user is in bluetooth group:
```bash
groups $USER
# Should include 'bluetooth'
```

If not, add user and reboot:
```bash
sudo usermod -a -G bluetooth $USER
sudo reboot
```

### Build Issues

If you encounter build errors:
```bash
flutter clean
flutter pub get
flutter run -d linux
```

## Development Tips

1. **Debugging**: Use `flutter run -d linux --verbose` for detailed logs
2. **Hot Reload**: Works on Linux - press 'r' in the terminal while app is running
3. **Device Testing**: Test with multiple devices for mesh functionality
4. **Performance**: Linux version optimized for desktop use

## System Requirements

- Ubuntu 18.04 LTS or newer
- 4GB RAM minimum (8GB recommended)
- Bluetooth 4.0+ adapter
- Internet connection for initial setup

## Known Limitations

- Bluetooth must be enabled at system level
- Some virtualized environments may not support Bluetooth
- WSL (Windows Subsystem for Linux) may have limited Bluetooth support
- Snap installation might not work in all environments (script provides manual fallback)

## Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Verify your system meets the requirements  
3. Run `flutter doctor` and resolve any issues
4. Check that Bluetooth works with `bluetoothctl scan on`
5. Create an issue on the GitHub repository with system details and error logs