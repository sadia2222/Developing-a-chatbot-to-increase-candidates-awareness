import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatBotApi {
  final String baseUrl = "https://Sadiaa-comsats-bot.hf.space";

  /// Create a new chat session
  Future<Map<String, dynamic>> createChat() async {
    final url = Uri.parse("$baseUrl/get_new_chat");
    final response = await http.post(url);

    if (response.statusCode == 200) {
      // Explicitly decode response as UTF-8
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Failed to create chat: ${response.reasonPhrase}");
    }
  }

  /// Send a question to the chatbot
  Future<Map<String, dynamic>> sendQuestion(String chatId, String question) async {
    final url = Uri.parse("$baseUrl/response");
    final payload = {"chat_id": chatId, "question": question};
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      // Explicitly decode response as UTF-8
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Failed to send question: ${response.reasonPhrase}");
    }
  }

  /// Get chat history
  Future<Map<String, dynamic>> getChatHistory(String chatId) async {
    final url = Uri.parse("$baseUrl/get_chat/$chatId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Explicitly decode response as UTF-8
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Failed to fetch chat history: ${response.reasonPhrase}");
    }
  }

  /// Delete a chat session
  Future<Map<String, dynamic>> deleteChat(String chatId) async {
    final url = Uri.parse("$baseUrl/delete_chat/$chatId");
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      // Explicitly decode response as UTF-8
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Failed to delete chat: ${response.reasonPhrase}");
    }
  }
}
