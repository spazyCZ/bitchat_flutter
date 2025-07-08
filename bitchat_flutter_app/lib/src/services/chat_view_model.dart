import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/bitchat_message.dart';
import '../models/bitchat_packet.dart';
import '../services/bluetooth_mesh_service.dart';

/// Main view model for chat functionality
class ChatViewModel extends ChangeNotifier {
  final BluetoothMeshService _meshService = BluetoothMeshService();
  
  // State
  final List<BitchatMessage> _messages = [];
  final Set<String> _connectedPeers = <String>{};
  final Map<String, String> _peerNicknames = {};
  String _nickname = '';
  String _currentChannel = '';
  bool _isConnected = false;
  
  // Stream subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _peerSubscription;
  StreamSubscription? _connectionSubscription;

  // Getters
  List<BitchatMessage> get messages => List.unmodifiable(_messages);
  Set<String> get connectedPeers => Set.from(_connectedPeers);
  Map<String, String> get peerNicknames => Map.from(_peerNicknames);
  String get nickname => _nickname;
  String get currentChannel => _currentChannel;
  bool get isConnected => _isConnected;
  String get myPeerID => _meshService.myPeerID;

  /// Initialize the chat system
  Future<void> initialize({String? nickname}) async {
    _nickname = nickname ?? _generateNickname();
    
    try {
      await _meshService.initialize(_nickname);
      _setupSubscriptions();
      
      // Add welcome message
      _addMessage(BitchatMessage.system('Welcome to bitchat* $_nickname'));
      _addMessage(BitchatMessage.system('Scanning for peers...'));
      
    } catch (e) {
      _addMessage(BitchatMessage.system('Error initializing: $e'));
    }
  }

  /// Start mesh networking
  Future<void> startNetworking() async {
    try {
      await _meshService.startMeshNetworking();
      _addMessage(BitchatMessage.system('Mesh networking started'));
    } catch (e) {
      _addMessage(BitchatMessage.system('Error starting networking: $e'));
    }
  }

  /// Send a chat message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Handle commands
    if (content.startsWith('/')) {
      await _handleCommand(content);
      return;
    }

    // Add message to local display
    final message = BitchatMessage(
      id: BitchatMessage._generateMessageId(),
      sender: _nickname,
      content: content,
      timestamp: DateTime.now(),
      senderPeerID: _meshService.myPeerID,
      channel: _currentChannel.isNotEmpty ? _currentChannel : null,
    );
    _addMessage(message);

    // Send over mesh network
    try {
      final payload = Uint8List.fromList(utf8.encode(content));
      await _meshService.sendMessage(
        type: MessageType.message,
        payload: payload,
      );
    } catch (e) {
      _addMessage(BitchatMessage.system('Failed to send message: $e'));
    }
  }

  /// Handle slash commands
  Future<void> _handleCommand(String command) async {
    final parts = command.split(' ');
    final cmd = parts[0].toLowerCase();

    switch (cmd) {
      case '/w':
      case '/who':
        _showConnectedPeers();
        break;
      
      case '/j':
      case '/join':
        if (parts.length > 1) {
          _joinChannel(parts[1]);
        } else {
          _addMessage(BitchatMessage.system('Usage: /join #channel'));
        }
        break;
      
      case '/leave':
        _leaveChannel();
        break;
      
      case '/nick':
        if (parts.length > 1) {
          _changeNickname(parts[1]);
        } else {
          _addMessage(BitchatMessage.system('Usage: /nick <new_nickname>'));
        }
        break;
      
      case '/clear':
        _clearMessages();
        break;
      
      case '/help':
        _showHelp();
        break;
      
      default:
        _addMessage(BitchatMessage.system('Unknown command: $cmd'));
    }
  }

  /// Show connected peers
  void _showConnectedPeers() {
    if (_connectedPeers.isEmpty) {
      _addMessage(BitchatMessage.system('No peers connected'));
    } else {
      final peerList = _connectedPeers.map((peerId) {
        final nickname = _peerNicknames[peerId] ?? peerId;
        return nickname;
      }).join(', ');
      _addMessage(BitchatMessage.system('Connected peers: $peerList'));
    }
  }

  /// Join a channel
  void _joinChannel(String channel) {
    if (!channel.startsWith('#')) {
      channel = '#$channel';
    }
    _currentChannel = channel;
    _addMessage(BitchatMessage.system('Joined channel: $channel'));
    notifyListeners();
  }

  /// Leave current channel
  void _leaveChannel() {
    if (_currentChannel.isNotEmpty) {
      _addMessage(BitchatMessage.system('Left channel: $_currentChannel'));
      _currentChannel = '';
      notifyListeners();
    } else {
      _addMessage(BitchatMessage.system('Not in a channel'));
    }
  }

  /// Change nickname
  void _changeNickname(String newNickname) {
    final oldNickname = _nickname;
    _nickname = newNickname;
    _addMessage(BitchatMessage.system('Nickname changed from $oldNickname to $newNickname'));
    notifyListeners();
  }

  /// Clear all messages
  void _clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// Show help text
  void _showHelp() {
    const helpText = '''
Available commands:
/w, /who - Show connected peers
/j, /join #channel - Join a channel
/leave - Leave current channel
/nick <nickname> - Change nickname
/clear - Clear messages
/help - Show this help
    ''';
    _addMessage(BitchatMessage.system(helpText.trim()));
  }

  /// Setup stream subscriptions
  void _setupSubscriptions() {
    _messageSubscription = _meshService.messageStream.listen(_handleIncomingMessage);
    _peerSubscription = _meshService.peerJoinStream.listen(_handlePeerJoin);
    _connectionSubscription = _meshService.connectionStatusStream.listen(_handleConnectionStatus);
  }

  /// Handle incoming message from mesh network
  void _handleIncomingMessage(BitchatPacket packet) {
    final content = utf8.decode(packet.payload);
    final senderNickname = _peerNicknames[packet.senderIDString] ?? packet.senderIDString;
    
    final message = BitchatMessage.fromPacket(
      senderNickname: senderNickname,
      content: content,
      timestamp: DateTime.fromMillisecondsSinceEpoch(packet.timestamp),
      senderPeerID: packet.senderIDString,
    );
    
    _addMessage(message);
  }

  /// Handle peer joining
  void _handlePeerJoin(String peerID) {
    if (!_connectedPeers.contains(peerID)) {
      _connectedPeers.add(peerID);
      _addMessage(BitchatMessage.system('Peer connected: $peerID'));
      notifyListeners();
    }
  }

  /// Handle connection status changes
  void _handleConnectionStatus(bool connected) {
    _isConnected = connected;
    if (connected) {
      _addMessage(BitchatMessage.system('Bluetooth connected'));
    } else {
      _addMessage(BitchatMessage.system('Bluetooth disconnected'));
    }
    notifyListeners();
  }

  /// Add a message to the list
  void _addMessage(BitchatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  /// Generate a random nickname
  String _generateNickname() {
    final adjectives = ['Quick', 'Silent', 'Bright', 'Swift', 'Clever', 'Bold'];
    final nouns = ['Fox', 'Wolf', 'Eagle', 'Hawk', 'Bear', 'Lion'];
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    
    final adjective = adjectives[random % adjectives.length];
    final noun = nouns[(random ~/ 10) % nouns.length];
    final number = random % 100;
    
    return '$adjective$noun$number';
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _peerSubscription?.cancel();
    _connectionSubscription?.cancel();
    _meshService.dispose();
    super.dispose();
  }
}