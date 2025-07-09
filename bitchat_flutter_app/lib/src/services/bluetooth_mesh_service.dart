import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cryptography/cryptography.dart';
import '../models/bitchat_packet.dart';
import '../services/binary_protocol.dart';
import 'encryption_service.dart';

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
  final EncryptionService _encryptionService = EncryptionService();
  final Map<String, Uint8List> _peerPublicKeys = {};
  final Map<String, SecretKey> _sharedSecrets = {};

  // For duplicate detection
  final Set<String> _recentMessageIds = <String>{};
  static const int _maxRecentMessages = 500;

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
    await _encryptionService.generateKeyPair();

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
    Uint8List encryptedPayload = payload;
    if (recipientID != null && _sharedSecrets.containsKey(recipientID)) {
      encryptedPayload = await _encryptionService.encrypt(payload, _sharedSecrets[recipientID]!);
    }
    final packet = BitchatPacket.create(
      messageType: type,
      senderIDString: _myPeerID,
      payload: encryptedPayload,
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

  /// Send our public key as part of announcement
  Future<void> _sendAnnouncement(BluetoothDevice device, BluetoothCharacteristic characteristic) async {
    final pubKey = await _encryptionService.getPublicKeyBytes();
    final announcePayload = Uint8List.fromList([..._nickname.codeUnits, ...?pubKey]);
    final packet = BitchatPacket.create(
      messageType: MessageType.announce,
      senderIDString: _myPeerID,
      payload: announcePayload,
      ttl: 1,
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

  /// Parse public key from announcement and compute shared secret
  void _handleAnnouncement(BluetoothDevice device, BitchatPacket packet) async {
    final payload = packet.payload;
    final peerNickname = String.fromCharCodes(payload.sublist(0, payload.length - 32));
    final peerPubKey = payload.sublist(payload.length - 32);
    final peerID = packet.senderIDString;
    if (!_connectedPeers.contains(peerID)) {
      _connectedPeers.add(peerID);
      _peerStreamController.add(peerID);
      print('Peer joined: $peerNickname ($peerID)');
    }
    _peerPublicKeys[peerID] = peerPubKey;
    _sharedSecrets[peerID] = await _encryptionService.computeSharedSecret(peerPubKey);
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
    if (packet.type == MessageType.message.value && packet.senderIDString != _myPeerID) {
      final peerID = packet.senderIDString;
      if (_sharedSecrets.containsKey(peerID)) {
        _encryptionService.decrypt(packet.payload, _sharedSecrets[peerID]!).then((decrypted) {
          final decryptedPacket = BitchatPacket(
            version: packet.version,
            type: packet.type,
            ttl: packet.ttl,
            timestamp: packet.timestamp,
            senderID: packet.senderID,
            recipientID: packet.recipientID,
            payload: decrypted,
            signature: packet.signature,
          );
          _handleMessage(decryptedPacket);
        }).catchError((_) {
          print('Failed to decrypt message from $peerID');
        });
        return;
      }
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

  /// Handle regular message
  void _handleMessage(BitchatPacket packet) {
    final messageId = _generateMessageIdFromPacket(packet);
    if (_recentMessageIds.contains(messageId)) {
      // Duplicate detected, ignore
      return;
    }
    _recentMessageIds.add(messageId);
    if (_recentMessageIds.length > _maxRecentMessages) {
      _recentMessageIds.remove(_recentMessageIds.first);
    }
    // Forward to listeners
    _messageStreamController.add(packet);

    // Relay message if TTL > 0 and we're not the sender
    if (packet.ttl > 0 && packet.senderIDString != _myPeerID) {
      _relayMessage(packet);
    }
  }

  String _generateMessageIdFromPacket(BitchatPacket packet) {
    // Use senderID + timestamp + type as a unique identifier
    return '${packet.senderIDString}_${packet.timestamp}_${packet.type}';
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

  // Channel password management
  final Map<String, String> _channelPasswords = {};

  /// Set a password for a channel
  void setChannelPassword(String channel, String password) {
    _channelPasswords[channel] = password;
  }

  /// Get the password for a channel (if any)
  String? getChannelPassword(String channel) {
    return _channelPasswords[channel];
  }

  /// Verify a password for a channel
  bool verifyChannelPassword(String channel, String password) {
    return _channelPasswords[channel] == password;
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