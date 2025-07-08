import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/bitchat_packet.dart';
import '../services/binary_protocol.dart';

/// Bluetooth Low Energy mesh networking service for bitchat
class BluetoothMeshService {
  // Service and characteristic UUIDs (must match Swift implementation)
  static const String serviceUUID = "F47B5E2D-4A9E-4C5A-9B3F-8E1D2C3A4B5C";
  static const String characteristicUUID = "A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D";

  // Stream controllers for events
  final _messageStreamController = StreamController<BitchatPacket>.broadcast();
  final _peerStreamController = StreamController<String>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  // Current state
  bool _isScanning = false;
  bool _isAdvertising = false;
  final Set<String> _connectedPeers = <String>{};
  final Map<String, BluetoothDevice> _connectedDevices = {};
  String _myPeerID = '';
  String _nickname = '';

  // Getters for streams
  Stream<BitchatPacket> get messageStream => _messageStreamController.stream;
  Stream<String> get peerJoinStream => _peerStreamController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  // Getters for state
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  Set<String> get connectedPeers => Set.from(_connectedPeers);
  String get myPeerID => _myPeerID;
  String get nickname => _nickname;

  /// Initialize the mesh service
  Future<void> initialize(String nickname) async {
    _nickname = nickname;
    _myPeerID = _generatePeerID();
    
    // Check if Bluetooth is available and enabled
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth not supported');
    }

    // Listen to Bluetooth adapter state
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        _connectionStatusController.add(true);
      } else {
        _connectionStatusController.add(false);
        _stopAll();
      }
    });
  }

  /// Start both scanning for peers and advertising our presence
  Future<void> startMeshNetworking() async {
    await startScanning();
    await startAdvertising();
  }

  /// Start scanning for nearby peers
  Future<void> startScanning() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      
      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          _handleScanResult(result);
        }
      });

      // Start scanning for our service UUID
      await FlutterBluePlus.startScan(
        withServices: [Guid(serviceUUID)],
        timeout: const Duration(seconds: 30),
        allowDuplicates: true,
      );
    } catch (e) {
      print('Error starting scan: $e');
      _isScanning = false;
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    if (!_isScanning) return;
    
    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  /// Start advertising our presence (requires platform-specific implementation)
  Future<void> startAdvertising() async {
    // Note: Bluetooth LE advertising is complex on mobile platforms
    // This is a placeholder - full implementation would require platform channels
    _isAdvertising = true;
    print('Advertising started (placeholder)');
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    _isAdvertising = false;
    print('Advertising stopped');
  }

  /// Send a message through the mesh network
  Future<void> sendMessage({
    required MessageType type,
    required Uint8List payload,
    String? recipientID,
    int ttl = 3,
  }) async {
    final packet = BitchatPacket.create(
      messageType: type,
      senderIDString: _myPeerID,
      payload: payload,
      recipientIDString: recipientID,
      ttl: ttl,
    );

    final binaryData = BinaryProtocol.encode(packet);
    if (binaryData == null) {
      print('Failed to encode message');
      return;
    }

    // Send to all connected peers
    for (final device in _connectedDevices.values) {
      await _sendDataToDevice(device, binaryData);
    }
  }

  /// Handle scan result - attempt to connect to discovered peers
  void _handleScanResult(ScanResult result) async {
    final device = result.device;
    
    // Skip if already connected
    if (_connectedDevices.containsKey(device.remoteId.toString())) {
      return;
    }

    try {
      // Connect to the device
      await device.connect(timeout: const Duration(seconds: 10));
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == serviceUUID.toUpperCase()) {
          await _handleService(device, service);
          break;
        }
      }
    } catch (e) {
      print('Error connecting to device ${device.remoteId}: $e');
    }
  }

  /// Handle discovered service - set up characteristics
  Future<void> _handleService(BluetoothDevice device, BluetoothService service) async {
    for (BluetoothCharacteristic characteristic in service.characteristics) {
      if (characteristic.uuid.toString().toUpperCase() == characteristicUUID.toUpperCase()) {
        
        // Subscribe to notifications
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          
          // Listen for incoming data
          characteristic.lastValueStream.listen((data) {
            _handleIncomingData(device, Uint8List.fromList(data));
          });
        }

        // Store the connection
        _connectedDevices[device.remoteId.toString()] = device;
        
        // Send announcement
        await _sendAnnouncement(device, characteristic);
        
        break;
      }
    }
  }

  /// Send announcement message to a newly connected peer
  Future<void> _sendAnnouncement(BluetoothDevice device, BluetoothCharacteristic characteristic) async {
    final announcePayload = Uint8List.fromList(_nickname.codeUnits);
    final packet = BitchatPacket.create(
      messageType: MessageType.announce,
      senderIDString: _myPeerID,
      payload: announcePayload,
      ttl: 1, // Don't relay announcements
    );

    final binaryData = BinaryProtocol.encode(packet);
    if (binaryData != null) {
      try {
        await characteristic.write(binaryData, withoutResponse: true);
      } catch (e) {
        print('Error sending announcement: $e');
      }
    }
  }

  /// Send binary data to a specific device
  Future<void> _sendDataToDevice(BluetoothDevice device, Uint8List data) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == serviceUUID.toUpperCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == characteristicUUID.toUpperCase()) {
              if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
                await characteristic.write(data, withoutResponse: true);
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error sending data to device: $e');
    }
  }

  /// Handle incoming data from a peer
  void _handleIncomingData(BluetoothDevice device, Uint8List data) {
    final packet = BinaryProtocol.decode(data);
    if (packet == null) {
      print('Failed to decode incoming packet');
      return;
    }

    // Handle different message types
    switch (MessageType.fromValue(packet.type)) {
      case MessageType.announce:
        _handleAnnouncement(device, packet);
        break;
      case MessageType.message:
        _handleMessage(packet);
        break;
      default:
        // Forward other message types to listeners
        _messageStreamController.add(packet);
    }
  }

  /// Handle peer announcement
  void _handleAnnouncement(BluetoothDevice device, BitchatPacket packet) {
    final peerNickname = String.fromCharCodes(packet.payload);
    final peerID = packet.senderIDString;
    
    if (!_connectedPeers.contains(peerID)) {
      _connectedPeers.add(peerID);
      _peerStreamController.add(peerID);
      print('Peer joined: $peerNickname ($peerID)');
    }
  }

  /// Handle regular message
  void _handleMessage(BitchatPacket packet) {
    // Forward to listeners
    _messageStreamController.add(packet);
    
    // Relay message if TTL > 0 and we're not the sender
    if (packet.ttl > 0 && packet.senderIDString != _myPeerID) {
      _relayMessage(packet);
    }
  }

  /// Relay message to other peers
  void _relayMessage(BitchatPacket packet) async {
    final relayPacket = packet.decrementTTL();
    final binaryData = BinaryProtocol.encode(relayPacket);
    
    if (binaryData != null) {
      for (final device in _connectedDevices.values) {
        await _sendDataToDevice(device, binaryData);
      }
    }
  }

  /// Generate a unique peer ID
  String _generatePeerID() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'peer$random';
  }

  /// Stop all networking activities
  void _stopAll() {
    _isScanning = false;
    _isAdvertising = false;
    _connectedPeers.clear();
    _connectedDevices.clear();
  }

  /// Clean up resources
  void dispose() {
    _stopAll();
    _messageStreamController.close();
    _peerStreamController.close();
    _connectionStatusController.close();
  }
}