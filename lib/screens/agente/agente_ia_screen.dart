import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import 'dart:convert';

class AiAgentScreen extends StatefulWidget {
  const AiAgentScreen({Key? key}) : super(key: key);

  @override
  _AiAgentScreenState createState() => _AiAgentScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String? time;

  _ChatMessage({required this.text, required this.isUser, this.time});
}

class _AiAgentScreenState extends State<AiAgentScreen> {
  final AiService _aiService = AiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: '¡Hola! Soy tu Agente Inteligente. ¿Qué trámite deseas realizar o en qué te puedo ayudar hoy?',
      isUser: false,
      time: _getCurrentTime(),
    ));
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: _getCurrentTime()));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.iniciarTramite(text);
      
      String replyText = '';
      if (response != null && response['confidence'] != null) {
        if (response['confidence'] > 0.6) {
          replyText = '¡Entendido! He identificado que deseas iniciar el trámite "${response['matchedPolicy']}".\n\n'
              'Voy a prepararlo para ti. En breve aparecerá en tu panel.';
        } else {
          replyText = 'No estoy del todo seguro de qué trámite necesitas. Quizás querías decir "${response['matchedPolicy']}".\n'
              '¿Podrías darme más detalles?';
        }
      } else {
        replyText = 'Lo siento, hubo un error procesando tu solicitud.';
      }

      setState(() {
        _messages.add(_ChatMessage(text: replyText, isUser: false, time: _getCurrentTime()));
        _isTyping = false;
      });
      _scrollToBottom();

    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
            text: 'Disculpa, estoy experimentando problemas de conexión. Intenta nuevamente.',
            isUser: false,
            time: _getCurrentTime()));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 0),
            bottomRight: Radius.circular(message.isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time ?? '',
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.black45,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              radius: 16,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Agente IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                Text(_isTyping ? 'Escribiendo...' : 'En línea', style: const TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('El agente está pensando...', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.mic, color: Colors.grey),
                            onPressed: () {
                              // Simulate voice input
                              _controller.text = "Quiero solicitar unas vacaciones de 5 días";
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Escribe tu solicitud...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
