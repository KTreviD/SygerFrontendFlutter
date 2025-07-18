import 'package:chat_support_app/widgets/typing_message.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/linkable_message.dart';
import '../models/message.dart';
import '../constants/colors.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

// Temporal message of "Escribiendo..." have the -1 id
class _ChatPageState extends State<ChatPage> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  int? userId;

  @override
  void initState() {
    super.initState();
    _initUserId();
  }

  Future<void> _initUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt('userId');

    setState(() {
      userId = storedId ?? _generateAndStoreUserId(prefs);
    });

    _loadConversation();
  }

  int _generateAndStoreUserId(SharedPreferences prefs) {
    final newId = DateTime.now().millisecondsSinceEpoch;
    prefs.setInt('userId', newId);
    return newId;
  }

  final List<Map<String, dynamic>> _moduleOptions = [
    {'label': 'Noticias', 'id': 2},
    {'label': 'Visitas', 'id': 3},
    {'label': 'Encuestas', 'id': 4},
    {'label': 'Reservaciones', 'id': 5},
    {'label': 'Botón Pánico', 'id': 6},
    {'label': 'Mi cuenta', 'id': 7},
    {'label': 'Hablar con una persona', 'id': 8},
  ];

  final List<Map<String, dynamic>> _answerOptions = [
    {'label': 'Sí, me fue útil', 'id': 9},
    {'label': 'No, no me fue útil', 'id': 10},
    {'label': 'Quiero preguntar sobre otra sección', 'id': 11},
    {'label': 'Quiero hacer otra pregunta sobre la misma sección', 'id': 12},
  ];

  Future<void> _loadConversation() async {
    try {
      final uri = Uri.https(
        'syger-backend-bot.vercel.app',
        '/messages/loadConversation',
        {'userId': userId.toString()},
      );
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Error al cargar la conversación');
      }

      final json = jsonDecode(response.body);
      final data = json['messages'] as List<dynamic>;

      final loadedMessages =
          data
              .map((msg) {
                try {
                  return Message.fromJson(msg);
                } catch (e, stacktrace) {
                  print('❌ Error al parsear mensaje: $e');
                  print(stacktrace);
                  return null;
                }
              })
              .whereType<Message>()
              .toList();

      setState(() {
        if (loadedMessages.isEmpty) {
          _messages.add(
            Message(
              userId,
              false,
              '¡Hola! Soy tu asistente SYGER, por favor escoge en qué sección de la app necesitas ayuda.',
              1,
            ),
          );
        } else {
          _messages.addAll(loadedMessages);
        }
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(
          Message(
            userId,
            false,
            'No se pudo cargar la conversación previa.',
            0,
          ),
        );
      });
    }
  }

  bool _shouldShowOptions() {
    if (_messages.isEmpty) return false;

    final lastMessage = _messages.last;

    if (lastMessage.isUser) return false;

    return lastMessage.messageTypeId == 1 || lastMessage.messageTypeId == 15;
  }

  void _handleOptionSelected(Map<String, dynamic> selectedOption) {
    _sendMessageWithPrompt(selectedOption['label'], selectedOption['id']);
  }

  Future<void> _sendMessageWithPrompt(String prompt, int messageTypeId) async {
    FocusScope.of(context).requestFocus(_focusNode);
    _scrollToBottom();

    final newMessage = Message(userId, true, prompt, messageTypeId);

    final futureResponse = http.post(
      Uri.parse('https://syger-backend-bot.vercel.app/messages/generateAnswer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userMessage': newMessage, 'messages': _messages}),
    );

    setState(() {
      _messages.add(newMessage);
      _messages.add(Message(userId, false, 'Escribiendo...', -1));
    });
    _scrollToBottom();

    futureResponse
        .then((response) {
          if (response.statusCode == 200) {
            final botReply = jsonDecode(response.body)['botMessage'];
            final botMessage = Message.fromJson(botReply);

            final userReply = jsonDecode(response.body)['userMessage'];
            final userMessage = Message.fromJson(userReply);

            setState(() {
              _messages.removeWhere(
                (msg) =>
                    msg.messageTypeId == -1 || msg.isUser && msg.id == null,
              );
              _messages.addAll([userMessage, botMessage]);
            });
          } else {
            setState(() {
              _messages.removeWhere((msg) => msg.messageTypeId == -1);
              _messages.add(
                Message(
                  userId,
                  false,
                  'Error al comunicarse con el servidor.',
                  0,
                ),
              );
            });
          }
          _scrollToBottom();
        })
        .catchError((e) {
          setState(() {
            _messages.removeWhere((msg) => msg.messageTypeId == -1);
            _messages.add(
              Message(
                userId,
                false,
                'No se pudo obtener una respuesta del servidor.',
                0,
              ),
            );
          });
          _scrollToBottom();
        });
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
    final lastMessageTypeId = _messages[_messages.length - 1].messageTypeId;
    int typeToSend = 0;

    switch (lastMessageTypeId) {
      case 16:
        typeToSend = 14;
        break;
      case 38:
        typeToSend = 46;
        break;
      case 39:
        typeToSend = 47;
        break;
      case 40:
        typeToSend = 48;
        break;
      case 41:
        typeToSend = 49;
        break;
      case 42:
        typeToSend = 50;
        break;
      case 43:
        typeToSend = 51;
        break;
      default:
        typeToSend = 0;
    }
    final newMessage = Message(userId, true, text, typeToSend);

    final futureResponse = http.post(
      Uri.parse('https://syger-backend-bot.vercel.app/messages/generateAnswer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userMessage': newMessage, 'messages': _messages}),
    );

    setState(() {
      _messages.add(newMessage);
      _messages.add(Message(userId, false, 'Escribiendo...', -1));
      _controller.clear();
    });
    _scrollToBottom();
    FocusScope.of(context).requestFocus(_focusNode);

    futureResponse
        .then((response) {
          if (response.statusCode == 200) {
            final botReply = jsonDecode(response.body)['botMessage'];
            final botMessage = Message.fromJson(botReply);

            final userReply = jsonDecode(response.body)['userMessage'];
            final userMessage = Message.fromJson(userReply);

            setState(() {
              _messages.removeWhere(
                (msg) =>
                    msg.messageTypeId == -1 || msg.isUser && msg.id == null,
              );
              _messages.addAll([userMessage, botMessage]);
            });
          } else {
            setState(() {
              _messages.removeWhere((msg) => msg.messageTypeId == -1);
              _messages.add(
                Message(
                  userId,
                  false,
                  'Error al comunicarse con el servidor.',
                  0,
                ),
              );
            });
          }
          _scrollToBottom();
        })
        .catchError((e) {
          setState(() {
            _messages.removeWhere((msg) => msg.messageTypeId == -1);
            _messages.add(
              Message(
                userId,
                false,
                'No se pudo obtener una respuesta del servidor.',
                0,
              ),
            );
          });
          _scrollToBottom();
        });
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

                if (msg.messageTypeId == -1) {
                  return const TypingMessage();
                }

                return LinkableMessage(text: msg.message, isUser: msg.isUser);
              },
            ),
          ),
          if (_shouldShowOptions())
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (_messages.last.messageTypeId == 15
                            ? _answerOptions
                            : _moduleOptions)
                        .map((option) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryApp,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _handleOptionSelected(option),
                            child: Text(option['label']),
                          );
                        })
                        .toList(),
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
