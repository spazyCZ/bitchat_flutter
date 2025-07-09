import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/bitchat_message.dart';

class PersistentStorageService {
  static const String messagesKey = 'bitchat_messages';

  Future<void> saveMessages(List<BitchatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((m) => m.toJson()).toList();
    await prefs.setString(messagesKey, jsonEncode(jsonList));
  }

  Future<List<BitchatMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(messagesKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((j) => BitchatMessage.fromJson(j)).toList();
  }

  Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(messagesKey);
  }
}
