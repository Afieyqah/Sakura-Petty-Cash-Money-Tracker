import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  // 1. Paste your real API Key here
  final String _apiKey = "AIzaSyBSjReQldADTToIhUaseroah1-HXXRiSC8"; 
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  ChatService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      requestOptions: const RequestOptions(apiVersion: 'v1'),
    );
    // Start a fresh session
    _chatSession = _model.startChat();
  }

  /// Sends a message and returns the AI's response text.
  Future<String> sendMessage(String message, List<Map<String, dynamic>> contextData) async {
    try {
      // Step 1: Format the expense data so the AI understands it
      final prompt = "Here are my expenses: $contextData. User question: $message";
      
      // Step 2: Send the message using the session
      final response = await _chatSession.sendMessage(Content.text(prompt));
      
      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      // Handle errors by checking the message string
      final errorStr = e.toString();
      if (errorStr.contains('403')) return "Error: Invalid API Key.";
      if (errorStr.contains('404')) return "Error: Model not found.";
      if (errorStr.contains('location')) return "Error: Not available in your region.";
      
      return "Connection Error: Please check your internet.";
    }
  }

  /// Resets the conversation history
  void resetChat() {
    _chatSession = _model.startChat();
  }
} // End of Class