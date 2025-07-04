import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/linkable_message.dart';
import '../models/message.dart';
import '../constants/colors.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _messages.add(
      Message(
        '¡Hola! Soy tu asistente SYGER. ¿En qué puedo ayudarte hoy?',
        false,
        options: ['Visitas', 'Pánico', 'Mi cuenta', 'Pagos'],
      ),
    );
  }

  void _handleOptionSelected(String option) {
    setState(() {
      _messages.add(Message(option, true));
    });
    _controller.text = option;
    _sendMessage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text, true));
      _controller.clear();
    });

    FocusScope.of(context).requestFocus(_focusNode);
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
          _messages.add(Message(reply, false));
        });
        _scrollToBottom();
      } else {
        throw Exception('Error al comunicarse con el servidor');
      }
    } catch (e) {
      setState(() {
        _messages.add(
          Message('No se pudo obtener una respuesta del servidor.', false),
        );
      });
      _scrollToBottom();
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
                if (!msg.isUser && msg.options != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinkableMessage(text: msg.text, isUser: msg.isUser),
                      Wrap(
                        spacing: 8,
                        children:
                            msg.options!.map((option) {
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryApp,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  _handleOptionSelected(option);
                                },
                                child: Text(option),
                              );
                            }).toList(),
                      ),
                    ],
                  );
                } else {
                  return LinkableMessage(text: msg.text, isUser: msg.isUser);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
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
                    backgroundColor: AppColors.primaryApp,
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
