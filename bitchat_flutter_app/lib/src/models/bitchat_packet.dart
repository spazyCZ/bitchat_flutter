import 'dart:typed_data';

/// Message types for the binary protocol
enum MessageType {
  message(0x01),
  announce(0x02),
  ack(0x03),
  channelJoin(0x04),
  channelLeave(0x05),
  privateMessage(0x06),
  deliveryAck(0x07),
  readReceipt(0x08),
  passwordProtectedChannelAnnouncement(0x09),
  leaveAnnouncement(0x0A),
  slap(0x0B),
  channelPasswordCommitment(0x0C),
  retentionSetting(0x0D),
  retentionToggle(0x0E);

  const MessageType(this.value);
  final int value;

  static MessageType? fromValue(int value) {
    for (MessageType type in MessageType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Binary protocol packet representation
class BitchatPacket {
  final int version;
  final int type;
  final int ttl;
  final int timestamp;
  final Uint8List senderID;
  final Uint8List? recipientID;
  final Uint8List payload;
  final Uint8List? signature;

  BitchatPacket({
    required this.version,
    required this.type,
    required this.ttl,
    required this.timestamp,
    required this.senderID,
    this.recipientID,
    required this.payload,
    this.signature,
  });

  /// Create a new packet for sending
  factory BitchatPacket.create({
    required MessageType messageType,
    required String senderIDString,
    required Uint8List payload,
    String? recipientIDString,
    int ttl = 3,
  }) {
    final senderID = _stringToFixedSizeBytes(senderIDString, 8);
    final recipientID = recipientIDString != null 
        ? _stringToFixedSizeBytes(recipientIDString, 8) 
        : null;
    
    return BitchatPacket(
      version: 1,
      type: messageType.value,
      ttl: ttl,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      senderID: senderID,
      recipientID: recipientID,
      payload: payload,
    );
  }

  /// Convert string to fixed-size byte array (padded with zeros)
  static Uint8List _stringToFixedSizeBytes(String str, int size) {
    final bytes = Uint8List(size);
    final strBytes = str.codeUnits.take(size).toList();
    for (int i = 0; i < strBytes.length; i++) {
      bytes[i] = strBytes[i];
    }
    return bytes;
  }

  /// Check if packet has recipient
  bool get hasRecipient => recipientID != null;

  /// Check if packet has signature
  bool get hasSignature => signature != null;

  /// Get sender ID as string
  String get senderIDString {
    // Find the first null byte and trim
    int length = senderID.length;
    for (int i = 0; i < senderID.length; i++) {
      if (senderID[i] == 0) {
        length = i;
        break;
      }
    }
    return String.fromCharCodes(senderID.take(length));
  }

  /// Get recipient ID as string
  String? get recipientIDString {
    if (recipientID == null) return null;
    
    // Find the first null byte and trim
    int length = recipientID!.length;
    for (int i = 0; i < recipientID!.length; i++) {
      if (recipientID![i] == 0) {
        length = i;
        break;
      }
    }
    return String.fromCharCodes(recipientID!.take(length));
  }

  /// Decrement TTL for forwarding
  BitchatPacket decrementTTL() {
    return BitchatPacket(
      version: version,
      type: type,
      ttl: ttl - 1,
      timestamp: timestamp,
      senderID: senderID,
      recipientID: recipientID,
      payload: payload,
      signature: signature,
    );
  }
}