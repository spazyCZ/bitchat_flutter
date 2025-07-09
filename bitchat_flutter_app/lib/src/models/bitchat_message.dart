/// Represents a chat message in the UI
class BitchatMessage {
  final String id;
  final String sender;
  final String content;
  final DateTime timestamp;
  final bool isRelay;
  final String? originalSender;
  final bool isPrivate;
  final String? recipientNickname;
  final String? senderPeerID;
  final List<String>? mentions;
  final String? channel;

  BitchatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isRelay = false,
    this.originalSender,
    this.isPrivate = false,
    this.recipientNickname,
    this.senderPeerID,
    this.mentions,
    this.channel,
  });

  /// Create a message from received packet data
  factory BitchatMessage.fromPacket({
    required String senderNickname,
    required String content,
    required DateTime timestamp,
    String? originalSender,
    bool isRelay = false,
    bool isPrivate = false,
    String? recipientNickname,
    String? senderPeerID,
    List<String>? mentions,
    String? channel,
  }) {
    return BitchatMessage(
      id: _generateMessageId(),
      sender: senderNickname,
      content: content,
      timestamp: timestamp,
      isRelay: isRelay,
      originalSender: originalSender,
      isPrivate: isPrivate,
      recipientNickname: recipientNickname,
      senderPeerID: senderPeerID,
      mentions: mentions,
      channel: channel,
    );
  }

  /// Create a system message
  factory BitchatMessage.system(String content) {
    return BitchatMessage(
      id: _generateMessageId(),
      sender: 'system',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  static String _generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (DateTime.now().microsecond % 1000).toString();
  }

  /// Check if this is a system message
  bool get isSystemMessage => sender == 'system';

  /// Check if this message mentions the given nickname
  bool mentionsUser(String nickname) {
    return mentions?.contains(nickname) ?? false;
  }

  /// Get display name for the sender
  String get displaySender {
    if (isRelay && originalSender != null) {
      return '$originalSender (via $sender)';
    }
    return sender;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'isRelay': isRelay,
    'originalSender': originalSender,
    'isPrivate': isPrivate,
    'recipientNickname': recipientNickname,
    'senderPeerID': senderPeerID,
    'mentions': mentions,
    'channel': channel,
  };

  factory BitchatMessage.fromJson(Map<String, dynamic> json) => BitchatMessage(
    id: json['id'],
    sender: json['sender'],
    content: json['content'],
    timestamp: DateTime.parse(json['timestamp']),
    isRelay: json['isRelay'] ?? false,
    originalSender: json['originalSender'],
    isPrivate: json['isPrivate'] ?? false,
    recipientNickname: json['recipientNickname'],
    senderPeerID: json['senderPeerID'],
    mentions: (json['mentions'] as List?)?.cast<String>(),
    channel: json['channel'],
  );

  static String generateMessageId() => _generateMessageId();
}