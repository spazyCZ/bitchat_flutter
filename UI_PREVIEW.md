# bitchat Flutter - BLE Scanner UI Preview

## What the Linux App Looks Like

The implemented BLE scanner provides a clean, terminal-inspired interface matching the bitchat design:

```
┌─ bitchat - BLE Device Scanner ──────────────────────────┐
│                                                          │
│  Scanning for nearby Bluetooth LE devices...           │
│  This is a basic BLE scanner for bitchat development.   │
│                                                          │
│  ┌─ Device List ────────────────────────────────────┐    │
│  │                                                   │    │
│  │  📱 iPhone 14                                     │    │
│  │  12:34:56:78:90:AB                         RSSI: -45 │
│  │                                                   │    │
│  │  🔵 Unknown Device                                │    │  
│  │  34:56:78:90:AB:CD                         RSSI: -67 │
│  │                                                   │    │
│  │  💻 MacBook Pro                                   │    │
│  │  56:78:90:AB:CD:EF                         RSSI: -52 │
│  │                                                   │    │
│  │  📺 Smart TV                                      │    │
│  │  78:90:AB:CD:EF:12                         RSSI: -78 │
│  │                                                   │    │
│  └───────────────────────────────────────────────────┘    │
│                                                          │
│                                     [🔍] Scan            │
└──────────────────────────────────────────────────────────┘
```

## Design Features

- **Dark Theme**: Black background with green text (bitchat colors)
- **Monospace Font**: Terminal-like appearance for technical feel
- **Real-time Updates**: Device list updates as new devices are discovered
- **RSSI Display**: Signal strength indicators for each device
- **Status Messages**: Clear indication of scanning state
- **Material Design**: Floating action button for scan control

## Key Functionality

### When Bluetooth is Off:
```
┌─ bitchat - BLE Device Scanner ──────────────────────────┐
│                                                          │
│  Bluetooth is currently disabled.                       │
│  Please enable Bluetooth to scan for devices.           │
│                                                          │
│  ┌─ No Devices ────────────────────────────────────┐     │
│  │                                                   │    │
│  │        No devices found yet                       │    │
│  │     Make sure Bluetooth is enabled               │    │
│  │                                                   │    │
│  └───────────────────────────────────────────────────┘    │
│                                                          │
│                                     [📶] Enable         │
└──────────────────────────────────────────────────────────┘
```

### During Scanning:
```
┌─ bitchat - BLE Device Scanner ──────────────────────────┐
│                                                          │
│  🔍 Scanning for nearby Bluetooth LE devices...        │
│  This is a basic BLE scanner for bitchat development.   │
│                                                          │
│  ┌─ Discovered Devices ──────────────────────────────┐   │
│  │                                                   │    │
│  │  [Found 3 devices in 2.4 seconds]               │    │
│  │                                                   │    │
│  │  ... device list here ...                        │    │
│  │                                                   │    │
│  └───────────────────────────────────────────────────┘    │
│  │                                                          │
│                                     [⏹️] Scanning...       │
└──────────────────────────────────────────────────────────┘
```

## Technical Notes

- Built with Flutter's Material Design components
- Uses flutter_blue_plus for cross-platform BLE support
- Automatically starts scanning when Bluetooth is enabled
- 5-second scan timeout with manual restart option
- Displays device names, MAC addresses, and signal strength
- Handles permission requests automatically

## Platform Integration

- Native GTK3 window on Linux
- Proper Linux desktop integration
- Responsive design for different screen sizes
- Keyboard navigation support
- System-level Bluetooth integration

This provides a solid foundation for bitchat development and testing on Linux Ubuntu systems.