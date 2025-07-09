import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bitchat_flutter/src/services/chat_view_model.dart';
import 'package:bitchat_flutter/src/models/bitchat_message.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatViewModel _chatViewModel = ChatViewModel();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      await _chatViewModel.initialize();
      await _chatViewModel.startNetworking();
      setState(() {
        _isInitialized = true;
      });
      
      // Listen to changes
      _chatViewModel.addListener(_onChatUpdate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing chat: $e')),
      );
    }
  }

  void _onChatUpdate() {
    setState(() {});
    
    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Initializing bitchat*...',
                style: TextStyle(
                  color: Colors.green,
                  fontFamily: 'monospace',
                  fontSize: 24, // Increased font size
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'bitchat*',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 32, // Increased font size
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _chatViewModel.nickname,
              style: const TextStyle(
                fontSize: 20, // Increased font size
                fontFamily: 'monospace',
                color: Colors.green,
              ),
            ),
            const Spacer(),
            _buildConnectionIndicator(),
          ],
        ),
        backgroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Column(
        children: [
          if (_chatViewModel.currentChannel.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.withOpacity(0.1),
              child: Text(
                'Channel: [36m[1m[4m[7m[0m[0m[0m[0m${_chatViewModel.currentChannel}',
                style: const TextStyle(
                  color: Colors.green,
                  fontFamily: 'monospace',
                  fontSize: 16, // Increased font size
                ),
              ),
            ),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPeerList,
        backgroundColor: Colors.green,
        child: const Icon(Icons.people, color: Colors.black),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _chatViewModel.isConnected ? Icons.bluetooth : Icons.bluetooth_disabled,
          color: _chatViewModel.isConnected ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${_chatViewModel.connectedPeers.length}',
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _chatViewModel.messages.length,
      itemBuilder: (context, index) {
        final message = _chatViewModel.messages[index];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(BitchatMessage message) {
    final isOwnMessage = message.sender == _chatViewModel.nickname;
    final isSystemMessage = message.isSystemMessage;

    if (isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '* ${message.content}',
          style: TextStyle(
            color: Colors.green.withOpacity(0.7),
            fontFamily: 'monospace',
            fontSize: 18, // Increased font size
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${_formatTime(message.timestamp)}]',
            style: TextStyle(
              color: Colors.green.withOpacity(0.5),
              fontFamily: 'monospace',
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '<${message.displaySender}>',
            style: TextStyle(
              color: isOwnMessage ? Colors.cyan : Colors.yellow,
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.content,
              style: const TextStyle(
                color: Colors.green,
                fontFamily: 'monospace',
                fontSize: 18, // Increased font size
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(
          top: BorderSide(color: Colors.green, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(
                color: Colors.green,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: _chatViewModel.currentChannel.isNotEmpty 
                    ? 'Message ${_chatViewModel.currentChannel}...'
                    : 'Type a message or /help...',
                hintStyle: TextStyle(
                  color: Colors.green.withOpacity(0.5),
                  fontFamily: 'monospace',
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onSubmitted: _sendMessage,
              textInputAction: TextInputAction.send,
            ),
          ),
          IconButton(
            onPressed: () => _sendMessage(_messageController.text),
            icon: const Icon(Icons.send, color: Colors.green),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isNotEmpty) {
      _chatViewModel.sendMessage(text.trim());
      _messageController.clear();
    }
  }

  void _showPeerList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Connected Peers',
          style: TextStyle(
            color: Colors.green,
            fontFamily: 'monospace',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your ID: ${_chatViewModel.myPeerID}',
              style: const TextStyle(
                color: Colors.cyan,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            if (_chatViewModel.connectedPeers.isEmpty)
              const Text(
                'No peers connected',
                style: TextStyle(
                  color: Colors.green,
                  fontFamily: 'monospace',
                ),
              )
            else
              ...(_chatViewModel.connectedPeers.toList()
                ..sort((a, b) {
                  final nameA = _chatViewModel.peerNicknames[a] ?? a;
                  final nameB = _chatViewModel.peerNicknames[b] ?? b;
                  return nameA.compareTo(nameB);
                })
              ).map(
                (peerID) => Text(
                  '• ${_chatViewModel.peerNicknames[peerID] ?? peerID}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _chatViewModel.removeListener(_onChatUpdate);
    _chatViewModel.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}