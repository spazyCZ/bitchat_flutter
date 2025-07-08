import 'package:flutter_test/flutter_test.dart';
import '../lib/src/models/bitchat_message.dart';

void main() {
  group('BitchatMessage Tests', () {
    test('should create basic message correctly', () {
      final message = BitchatMessage(
        id: 'test123',
        sender: 'alice',
        content: 'Hello world',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

      expect(message.id, equals('test123'));
      expect(message.sender, equals('alice'));
      expect(message.content, equals('Hello world'));
      expect(message.isRelay, isFalse);
      expect(message.isPrivate, isFalse);
      expect(message.isSystemMessage, isFalse);
    });

    test('should create system message', () {
      final message = BitchatMessage.system('Connection established');

      expect(message.sender, equals('system'));
      expect(message.content, equals('Connection established'));
      expect(message.isSystemMessage, isTrue);
    });

    test('should create message from packet data', () {
      final message = BitchatMessage.fromPacket(
        senderNickname: 'bob',
        content: 'Test message',
        timestamp: DateTime.now(),
        isRelay: true,
        originalSender: 'alice',
      );

      expect(message.sender, equals('bob'));
      expect(message.content, equals('Test message'));
      expect(message.isRelay, isTrue);
      expect(message.originalSender, equals('alice'));
    });

    test('should handle display sender for relayed messages', () {
      final relayedMessage = BitchatMessage(
        id: 'test',
        sender: 'relay_node',
        content: 'Relayed content',
        timestamp: DateTime.now(),
        isRelay: true,
        originalSender: 'original_sender',
      );

      expect(relayedMessage.displaySender, equals('original_sender (via relay_node)'));

      final directMessage = BitchatMessage(
        id: 'test2',
        sender: 'direct_sender',
        content: 'Direct content',
        timestamp: DateTime.now(),
      );

      expect(directMessage.displaySender, equals('direct_sender'));
    });

    test('should detect mentions', () {
      final message = BitchatMessage(
        id: 'test',
        sender: 'alice',
        content: 'Hello @bob and @charlie',
        timestamp: DateTime.now(),
        mentions: ['bob', 'charlie'],
      );

      expect(message.mentionsUser('bob'), isTrue);
      expect(message.mentionsUser('charlie'), isTrue);
      expect(message.mentionsUser('dave'), isFalse);
    });

    test('should handle private messages', () {
      final message = BitchatMessage(
        id: 'private1',
        sender: 'alice',
        content: 'Secret message',
        timestamp: DateTime.now(),
        isPrivate: true,
        recipientNickname: 'bob',
      );

      expect(message.isPrivate, isTrue);
      expect(message.recipientNickname, equals('bob'));
    });

    test('should generate unique IDs', () {
      final message1 = BitchatMessage.system('Test 1');
      final message2 = BitchatMessage.system('Test 2');

      expect(message1.id, isNot(equals(message2.id)));
    });
  });
}