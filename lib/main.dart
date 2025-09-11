import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const BLEScanPage(),
      debugShowCheckedModeBanner: false,
      title: 'bitchat Flutter',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.green,
        ),
      ),
    );
  }
}

class BLEScanPage extends StatefulWidget {
  const BLEScanPage({super.key});

  @override
  State<BLEScanPage> createState() => _BLEScanPageState();
}

class _BLEScanPageState extends State<BLEScanPage> {
  List<ScanResult> devices = [];
  bool scanning = false;

  void startScan() {
    setState(() {
      devices.clear();
      scanning = true;
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5)).listen(
      (scanResult) {
        setState(() {
          devices.add(scanResult);
        });
      },
      onDone: () => setState(() => scanning = false),
    );
  }

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        startScan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('bitchat - BLE Device Scanner'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scanning ? null : startScan,
        child: Icon(scanning ? Icons.bluetooth_searching : Icons.bluetooth),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Scanning for nearby Bluetooth LE devices...\nThis is a basic BLE scanner for bitchat development.',
              style: TextStyle(
                color: Colors.green,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: devices.isEmpty
                ? const Center(
                    child: Text(
                      'No devices found yet\nMake sure Bluetooth is enabled',
                      style: TextStyle(color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, i) => Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        title: Text(
                          devices[i].device.platformName.isNotEmpty
                              ? devices[i].device.platformName
                              : "Unknown Device",
                          style: const TextStyle(color: Colors.green),
                        ),
                        subtitle: Text(
                          devices[i].device.remoteId.toString(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Text(
                          'RSSI: ${devices[i].rssi}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
