import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/models/bitchat_packet.dart';
import '../lib/src/services/binary_protocol.dart';

void main() {
  group('BinaryProtocol Tests', () {
    test('should encode and decode basic message packet', () {
      // Create a test packet
      final payload = Uint8List.fromList('Hello, mesh!'.codeUnits);
      final packet = BitchatPacket.create(
        messageType: MessageType.message,
        senderIDString: 'peer1234',
        payload: payload,
        ttl: 3,
      );

      // Encode to binary
      final encoded = BinaryProtocol.encode(packet);
      expect(encoded, isNotNull);
      expect(encoded!.length, greaterThan(0));

      // Decode back
      final decoded = BinaryProtocol.decode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.type, equals(MessageType.message.value));
      expect(decoded.senderIDString, equals('peer1234'));
      expect(decoded.payload, equals(payload));
      expect(decoded.ttl, equals(3));
    });

    test('should handle packet with recipient', () {
      final payload = Uint8List.fromList('Private message'.codeUnits);
      final packet = BitchatPacket.create(
        messageType: MessageType.privateMessage,
        senderIDString: 'alice123',
        payload: payload,
        recipientIDString: 'bob456',
        ttl: 2,
      );

      final encoded = BinaryProtocol.encode(packet);
      expect(encoded, isNotNull);

      final decoded = BinaryProtocol.decode(encoded!);
      expect(decoded, isNotNull);
      expect(decoded!.hasRecipient, isTrue);
      expect(decoded.recipientIDString, equals('bob456'));
    });

    test('should handle empty payload', () {
      final packet = BitchatPacket.create(
        messageType: MessageType.announce,
        senderIDString: 'test',
        payload: Uint8List(0),
      );

      final encoded = BinaryProtocol.encode(packet);
      expect(encoded, isNotNull);

      final decoded = BinaryProtocol.decode(encoded!);
      expect(decoded, isNotNull);
      expect(decoded!.payload.length, equals(0));
    });

    test('should reject invalid data', () {
      // Too short data
      final shortData = Uint8List.fromList([1, 2, 3]);
      final decoded = BinaryProtocol.decode(shortData);
      expect(decoded, isNull);
    });

    test('should handle TTL decrement', () {
      final packet = BitchatPacket.create(
        messageType: MessageType.message,
        senderIDString: 'relay',
        payload: Uint8List.fromList('Forward me'.codeUnits),
        ttl: 5,
      );

      final decremented = packet.decrementTTL();
      expect(decremented.ttl, equals(4));
      expect(decremented.senderIDString, equals(packet.senderIDString));
    });
  });

  group('BitchatPacket Tests', () {
    test('should create packet with correct properties', () {
      final packet = BitchatPacket.create(
        messageType: MessageType.channelJoin,
        senderIDString: 'user123',
        payload: Uint8List.fromList('#general'.codeUnits),
      );

      expect(packet.version, equals(1));
      expect(packet.type, equals(MessageType.channelJoin.value));
      expect(packet.senderIDString, equals('user123'));
      expect(packet.hasRecipient, isFalse);
      expect(packet.hasSignature, isFalse);
    });

    test('should handle long sender ID gracefully', () {
      final longSenderID = 'very_long_sender_id_that_exceeds_8_bytes';
      final packet = BitchatPacket.create(
        messageType: MessageType.announce,
        senderIDString: longSenderID,
        payload: Uint8List.fromList('test'.codeUnits),
      );

      // Should truncate to 8 bytes
      expect(packet.senderID.length, equals(8));
      expect(packet.senderIDString.length, lessThanOrEqualTo(8));
    });
  });

  group('MessageType Tests', () {
    test('should convert between enum and value', () {
      expect(MessageType.message.value, equals(0x01));
      expect(MessageType.announce.value, equals(0x02));
      expect(MessageType.privateMessage.value, equals(0x06));

      expect(MessageType.fromValue(0x01), equals(MessageType.message));
      expect(MessageType.fromValue(0x02), equals(MessageType.announce));
      expect(MessageType.fromValue(0xFF), isNull);
    });
  });
}