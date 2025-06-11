import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ChatSupportApp());
}

class ChatSupportApp extends StatelessWidget {
  const ChatSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Support',
      theme: ThemeData(
        primaryColor: const Color(0xFFD93A00),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD93A00),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(color: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatPage()),
          );
        },
        backgroundColor: const Color(0xFFD93A00),
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<_Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages.add(
      _Message(
        '¡Hola! Soy tu asistente SYGER. ¿En qué puedo ayudarte hoy?',
        false,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text, true));
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://syger-backend-bot.vercel.app/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': text}),
      );

      if (response.statusCode == 200) {
        final reply = jsonDecode(response.body)['response'];
        setState(() {
          _messages.add(_Message(reply, false));
        });
        _scrollToBottom(); // Desplázate después de un error
      } else {
        throw Exception('Error al comunicarse con el servidor');
      }
    } catch (e) {
      setState(() {
        _messages.add(
          _Message('No se pudo obtener una respuesta del servidor.', false),
        );
      });
      _scrollToBottom(); // Desplázate después de un error
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente SYGER'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          msg.isUser
                              ? const Color(0xFFD93A00)
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      border:
                          msg.isUser ? Border.all(color: Colors.grey) : null,
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD93A00),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _sendMessage,
                  child: const Text('Enviar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;

  _Message(this.text, this.isUser);
}
