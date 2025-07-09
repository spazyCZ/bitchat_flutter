import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:io' show Platform;

void main() {
  runApp(const BitchatApp());
}

class BitchatApp extends StatelessWidget {
  const BitchatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bitchat Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScanPage(),
    );
  }
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  FlutterReactiveBle? _ble;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  final List<DiscoveredDevice> _devices = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        _ble = FlutterReactiveBle();
      } catch (_) {
        // Plugin not available in this environment (e.g. tests)
      }
    }
  }

  void _startScan() {
    if (_ble == null) return;
    setState(() {
      _devices.clear();
      _scanning = true;
    });
    _scanSub = _ble!
        .scanForDevices(withServices: const [], scanMode: ScanMode.lowLatency)
        .listen((device) {
      final index = _devices.indexWhere((d) => d.id == device.id);
      if (index == -1) {
        setState(() => _devices.add(device));
      } else {
        setState(() => _devices[index] = device);
      }
    });
  }

  void _stopScan() {
    _scanSub?.cancel();
    setState(() => _scanning = false);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Scan')),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanning ? _stopScan : _startScan,
        child: Icon(_scanning ? Icons.stop : Icons.search),
      ),
      body: ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final d = _devices[index];
          return ListTile(
            title: Text(d.name.isNotEmpty ? d.name : d.id),
            subtitle: Text('RSSI: ${d.rssi}'),
          );
        },
      ),
    );
  }
}

