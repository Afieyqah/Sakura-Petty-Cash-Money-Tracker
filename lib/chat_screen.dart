import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// --- SERVICE CLASS (Logic & API) ---
class ChatService {
  // 1. PLACE YOUR REAL KEY HERE
  final String _apiKey = "AIzaSyBSjReQldADTToIhUaseroah1-HXXRiSC8"; 
  late final GenerativeModel _model;

  ChatService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', 
      apiKey: _apiKey,
      // Fixing the "Model Not Found" error by specifying the request options
      requestOptions: const RequestOptions(apiVersion: 'v1'),
    );
  }

  Future<String> getResponse(String userPrompt, List<Map<String, dynamic>> expenses) async {
    try {
      // We give the AI context so it knows what expenses you have
      final prompt = "Context: My current expenses are $expenses. Question: $userPrompt";
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? "I'm sorry, I couldn't generate a response.";
    } catch (e) {
      return "Connection Error: $e";
    }
  }
}

// --- UI CLASS (Chat Screen) ---
class ChatScreen extends StatefulWidget {
  final List<Map<String, dynamic>> expenses;
  const ChatScreen({super.key, required this.expenses});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  late final ChatService _aiService;

  @override
  void initState() {
    super.initState();
    _aiService = ChatService(); // Initializes the service once
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    
    final userText = _controller.text;
    setState(() {
      _messages.add({"role": "user", "text": userText});
      _isLoading = true;
    });
    _controller.clear();

    // Call our service
    final botResponse = await _aiService.getResponse(userText, widget.expenses);

    setState(() {
      _messages.add({"role": "bot", "text": botResponse});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Finance Assistant", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final isUser = _messages[i]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.purple[100] : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: isUser ? const Radius.circular(15) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(15),
                      ),
                    ),
                    child: Text(_messages[i]['text']!),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) 
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(color: Colors.purple),
            ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask about your spending...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}