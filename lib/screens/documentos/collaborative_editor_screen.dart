import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../services/auth_service.dart';

class CollaborativeEditorScreen extends StatefulWidget {
  final String docId;

  const CollaborativeEditorScreen({Key? key, required this.docId}) : super(key: key);

  @override
  _CollaborativeEditorScreenState createState() => _CollaborativeEditorScreenState();
}

class _CollaborativeEditorScreenState extends State<CollaborativeEditorScreen> {
  StompClient? _stompClient;
  final TextEditingController _controller = TextEditingController();
  bool _isConnected = false;
  int _activeUsersCount = 1;
  bool _isRemoteUpdate = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _controller.addListener(_onContentChanged);
  }

  void _connectWebSocket() {
    // We assume backend is running on 10.0.2.2:8080 for Android Emulator or localhost for Web
    final url = 'ws://10.0.2.2:8080/ws';

    _stompClient = StompClient(
      config: StompConfig(
        url: url,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) => print(error.toString()),
      ),
    );
    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    setState(() => _isConnected = true);

    // Subscribe to content updates
    _stompClient!.subscribe(
      destination: '/topic/collab/${widget.docId}',
      callback: (frame) {
        if (frame.body != null) {
          _isRemoteUpdate = true;
          final currentCursor = _controller.selection;
          _controller.text = frame.body!;
          // Try to maintain cursor position
          if (currentCursor.baseOffset <= _controller.text.length) {
            _controller.selection = currentCursor;
          } else {
            _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
          }
          _isRemoteUpdate = false;
        }
      },
    );

    // Subscribe to users count updates
    _stompClient!.subscribe(
      destination: '/topic/collab/${widget.docId}/users',
      callback: (frame) {
        if (frame.body != null) {
          setState(() {
            _activeUsersCount = int.tryParse(frame.body!) ?? 1;
          });
        }
      },
    );
  }

  void _onContentChanged() {
    if (_isRemoteUpdate || !_isConnected) return;
    _stompClient!.send(
      destination: '/app/collab/${widget.docId}',
      body: _controller.text,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _stompClient?.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edición Colaborativa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            Text('Doc: ${widget.docId}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_activeUsersCount editando',
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          style: const TextStyle(fontSize: 16, height: 1.5),
          decoration: const InputDecoration(
            hintText: 'Escribe aquí... Los cambios se sincronizarán en tiempo real con otros usuarios.',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
