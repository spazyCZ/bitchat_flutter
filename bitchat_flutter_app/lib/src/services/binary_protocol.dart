import 'dart:typed_data';
import 'dart:convert';
import '../models/bitchat_packet.dart';

/// Binary protocol encoder/decoder for efficient Bluetooth LE communication
class BinaryProtocol {
  static const int headerSize = 13;
  static const int senderIDSize = 8;
  static const int recipientIDSize = 8;
  static const int signatureSize = 64;

  /// Protocol flags
  static const int flagHasRecipient = 0x01;
  static const int flagHasSignature = 0x02;
  static const int flagIsCompressed = 0x04;

  /// Encode a BitchatPacket to binary format
  static Uint8List? encode(BitchatPacket packet) {
    try {
      final data = BytesBuilder();
      
      // Header (13 bytes total)
      data.addByte(packet.version);      // 1 byte
      data.addByte(packet.type);         // 1 byte  
      data.addByte(packet.ttl);          // 1 byte
      
      // Timestamp (8 bytes, big-endian)
      _addUint64BigEndian(data, packet.timestamp);
      
      // Flags (1 byte)
      int flags = 0;
      if (packet.hasRecipient) flags |= flagHasRecipient;
      if (packet.hasSignature) flags |= flagHasSignature;
      data.addByte(flags);
      
      // Payload length (2 bytes, big-endian)
      _addUint16BigEndian(data, packet.payload.length);
      
      // Sender ID (exactly 8 bytes)
      _addFixedBytes(data, packet.senderID, senderIDSize);
      
      // Recipient ID (8 bytes, if present)
      if (packet.hasRecipient) {
        _addFixedBytes(data, packet.recipientID!, recipientIDSize);
      }
      
      // Payload
      data.add(packet.payload);
      
      // Signature (64 bytes, if present)
      if (packet.hasSignature) {
        _addFixedBytes(data, packet.signature!, signatureSize);
      }
      
      return data.toBytes();
    } catch (e) {
      print('Error encoding packet: $e');
      return null;
    }
  }

  /// Decode binary data to BitchatPacket
  static BitchatPacket? decode(Uint8List data) {
    try {
      if (data.length < headerSize) return null;
      
      int offset = 0;
      
      // Parse header
      final version = data[offset++];
      final type = data[offset++];
      final ttl = data[offset++];
      
      // Timestamp (8 bytes, big-endian)
      final timestamp = _readUint64BigEndian(data, offset);
      offset += 8;
      
      // Flags
      final flags = data[offset++];
      final hasRecipient = (flags & flagHasRecipient) != 0;
      final hasSignature = (flags & flagHasSignature) != 0;
      
      // Payload length
      final payloadLength = _readUint16BigEndian(data, offset);
      offset += 2;
      
      // Sender ID (8 bytes)
      final senderID = _readFixedBytes(data, offset, senderIDSize);
      offset += senderIDSize;
      
      // Recipient ID (8 bytes, if present)
      Uint8List? recipientID;
      if (hasRecipient) {
        recipientID = _readFixedBytes(data, offset, recipientIDSize);
        offset += recipientIDSize;
      }
      
      // Check if we have enough data for payload
      if (offset + payloadLength > data.length) return null;
      
      // Payload
      final payload = Uint8List.fromList(
        data.sublist(offset, offset + payloadLength)
      );
      offset += payloadLength;
      
      // Signature (64 bytes, if present)
      Uint8List? signature;
      if (hasSignature) {
        if (offset + signatureSize > data.length) return null;
        signature = _readFixedBytes(data, offset, signatureSize);
      }
      
      return BitchatPacket(
        version: version,
        type: type,
        ttl: ttl,
        timestamp: timestamp,
        senderID: senderID,
        recipientID: recipientID,
        payload: payload,
        signature: signature,
      );
    } catch (e) {
      print('Error decoding packet: $e');
      return null;
    }
  }

  /// Add uint64 in big-endian format
  static void _addUint64BigEndian(BytesBuilder builder, int value) {
    for (int i = 7; i >= 0; i--) {
      builder.addByte((value >> (i * 8)) & 0xFF);
    }
  }

  /// Add uint16 in big-endian format
  static void _addUint16BigEndian(BytesBuilder builder, int value) {
    builder.addByte((value >> 8) & 0xFF);
    builder.addByte(value & 0xFF);
  }

  /// Add fixed-size byte array, padding with zeros if needed
  static void _addFixedBytes(BytesBuilder builder, Uint8List bytes, int size) {
    final fixedBytes = Uint8List(size);
    final copyLength = bytes.length < size ? bytes.length : size;
    for (int i = 0; i < copyLength; i++) {
      fixedBytes[i] = bytes[i];
    }
    builder.add(fixedBytes);
  }

  /// Read uint64 in big-endian format
  static int _readUint64BigEndian(Uint8List data, int offset) {
    int value = 0;
    for (int i = 0; i < 8; i++) {
      value = (value << 8) | data[offset + i];
    }
    return value;
  }

  /// Read uint16 in big-endian format
  static int _readUint16BigEndian(Uint8List data, int offset) {
    return (data[offset] << 8) | data[offset + 1];
  }

  /// Read fixed-size byte array
  static Uint8List _readFixedBytes(Uint8List data, int offset, int size) {
    return Uint8List.fromList(data.sublist(offset, offset + size));
  }
}