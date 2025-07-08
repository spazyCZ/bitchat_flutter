import 'dart:typed_data';
import '../lib/src/models/bitchat_packet.dart';
import '../lib/src/services/binary_protocol.dart';
import '../lib/src/models/bitchat_message.dart';

/// Example demonstrating how to use the bitchat Flutter components
void main() {
  print('=== Bitchat Flutter Usage Examples ===\n');

  // Example 1: Creating and encoding a message packet
  print('1. Creating a message packet:');
  final messagePayload = Uint8List.fromList('Hello, mesh network!'.codeUnits);
  final messagePacket = BitchatPacket.create(
    messageType: MessageType.message,
    senderIDString: 'alice123',
    payload: messagePayload,
    ttl: 3,
  );

  print('   Sender: ${messagePacket.senderIDString}');
  print('   TTL: ${messagePacket.ttl}');
  print('   Payload: ${String.fromCharCodes(messagePacket.payload)}');

  // Example 2: Binary encoding/decoding
  print('\n2. Binary protocol encoding:');
  final encoded = BinaryProtocol.encode(messagePacket);
  if (encoded != null) {
    print('   Encoded size: ${encoded.length} bytes');
    print('   First few bytes: ${encoded.take(10).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');

    // Decode it back
    final decoded = BinaryProtocol.decode(encoded);
    if (decoded != null) {
      print('   Decoded successfully: ${decoded.senderIDString}');
    }
  }

  // Example 3: Private message
  print('\n3. Creating a private message:');
  final privatePayload = Uint8List.fromList('Secret message'.codeUnits);
  final privatePacket = BitchatPacket.create(
    messageType: MessageType.privateMessage,
    senderIDString: 'alice123',
    payload: privatePayload,
    recipientIDString: 'bob456',
    ttl: 2,
  );

  print('   From: ${privatePacket.senderIDString}');
  print('   To: ${privatePacket.recipientIDString}');
  print('   Has recipient: ${privatePacket.hasRecipient}');

  // Example 4: Message objects for UI
  print('\n4. Creating UI message objects:');
  final chatMessage = BitchatMessage.fromPacket(
    senderNickname: 'Alice',
    content: 'Hello everyone!',
    timestamp: DateTime.now(),
    senderPeerID: 'alice123',
  );

  print('   Display sender: ${chatMessage.displaySender}');
  print('   Content: ${chatMessage.content}');
  print('   Timestamp: ${chatMessage.timestamp}');

  // Example 5: System message
  print('\n5. System messages:');
  final systemMessage = BitchatMessage.system('Peer connected: Bob');
  print('   Is system message: ${systemMessage.isSystemMessage}');
  print('   Content: ${systemMessage.content}');

  // Example 6: Relayed message
  print('\n6. Relayed message:');
  final relayedMessage = BitchatMessage.fromPacket(
    senderNickname: 'RelayNode',
    content: 'This was forwarded',
    timestamp: DateTime.now(),
    isRelay: true,
    originalSender: 'OriginalSender',
  );

  print('   Display sender: ${relayedMessage.displaySender}');
  print('   Is relay: ${relayedMessage.isRelay}');

  // Example 7: Message types
  print('\n7. Available message types:');
  for (final type in MessageType.values) {
    print('   ${type.name}: 0x${type.value.toRadixString(16).padLeft(2, '0')}');
  }

  print('\n=== Example Usage Complete ===');
}

/// Example of how the BluetoothMeshService would be used in a real app
/// (This is pseudo-code since we can't actually run BLE in this environment)
void exampleBluetoothUsage() {
  print('\n=== Bluetooth Service Usage Example ===');
  
  // This is how you would use the BluetoothMeshService in a real app:
  /*
  final meshService = BluetoothMeshService();
  
  // Initialize with nickname
  await meshService.initialize('Alice');
  
  // Listen for messages
  meshService.messageStream.listen((packet) {
    final content = String.fromCharCodes(packet.payload);
    print('Received: $content from ${packet.senderIDString}');
  });
  
  // Listen for peer connections
  meshService.peerJoinStream.listen((peerID) {
    print('Peer joined: $peerID');
  });
  
  // Start networking
  await meshService.startMeshNetworking();
  
  // Send a message
  final payload = Uint8List.fromList('Hello mesh!'.codeUnits);
  await meshService.sendMessage(
    type: MessageType.message,
    payload: payload,
  );
  */
  
  print('   [Bluetooth functionality requires physical devices]');
  print('   See lib/src/services/bluetooth_mesh_service.dart for implementation');
}