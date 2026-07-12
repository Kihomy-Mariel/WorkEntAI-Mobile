import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import '../../services/api_service.dart';
import '../../services/app_provider.dart';

/// Pantalla del Agente Inteligente de Atención al Cliente (CU-22/23).
///
/// Permite al cliente chatear con la IA para identificar una política y
/// completar los requisitos del trámite en un diálogo guiado interactivo.
class AgenteScreen extends StatefulWidget {
  const AgenteScreen({super.key});

  @override
  State<AgenteScreen> createState() => _AgenteScreenState();
}

class _AgenteScreenState extends State<AgenteScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String? _sessionId;
  String _fase = 'IDENTIFICACION';
  List<Map<String, dynamic>> _mensajes = [];
  Map<String, dynamic> _datosRecopilados = {};
  String? _politicaId;
  String? _politicaNombre;

  bool _inicializando = true;
  bool _enviando = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AppProvider>().isOffline) {
        setState(() {
          _inicializando = false;
          _error = 'El Asistente IA requiere conexión a internet para funcionar.';
        });
      } else {
        _iniciarSesion();
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    try {
      setState(() {
        _inicializando = true;
        _error = '';
      });

      final session = await _apiService.iniciarAgenteSesion();
      
      setState(() {
        _sessionId = session['id'];
        _fase = session['fase'] ?? 'IDENTIFICACION';
        _politicaId = session['politicaId'];
        _politicaNombre = session['nombrePolitica'];
        _datosRecopilados = session['datosRecopilados'] ?? {};
        
        final List<dynamic>? rawMensajes = session['mensajes'];
        if (rawMensajes != null) {
          _mensajes = rawMensajes.map((m) => Map<String, dynamic>.from(m)).toList();
        }

        // Si es una sesión nueva sin mensajes, agregamos el saludo inicial
        if (_mensajes.isEmpty) {
          _mensajes.add({
            'rol': 'asistente',
            'contenido': '¡Hola! Soy tu Asistente IA. Cuéntame brevemente qué tipo de trámite o solicitud deseas realizar para guiarte en el proceso.',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
        
        _inicializando = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = 'No se pudo iniciar la sesión con el asistente: ${e.toString()}';
        _inicializando = false;
      });
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _inputCtrl.text.trim();
    if (texto.isEmpty || _sessionId == null || _enviando) return;

    _inputCtrl.clear();
    setState(() {
      _enviando = true;
      _mensajes.add({
        'rol': 'usuario',
        'contenido': texto,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    try {
      final session = await _apiService.enviarAgenteMensaje(_sessionId!, texto);
      
      setState(() {
        _fase = session['fase'] ?? 'IDENTIFICACION';
        _politicaId = session['politicaId'];
        _politicaNombre = session['nombrePolitica'];
        _datosRecopilados = session['datosRecopilados'] ?? {};
        
        final List<dynamic>? rawMensajes = session['mensajes'];
        if (rawMensajes != null) {
          _mensajes = rawMensajes.map((m) => Map<String, dynamic>.from(m)).toList();
        }
        _enviando = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _mensajes.add({
          'rol': 'asistente',
          'contenido': 'Lo siento, ocurrió un error procesando tu mensaje: ${e.toString()}',
          'timestamp': DateTime.now().toIso8601String(),
        });
        _enviando = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _volverPortal() async {
    // Limpiar sesión del agente en el backend
    try {
      if (_sessionId != null) {
        await _apiService.cerrarAgenteSesion(_sessionId!);
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context); // Volver al portal
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<AppProvider>().isOffline;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🤖 ', style: TextStyle(fontSize: 20)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente IA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  'Guía interactiva de trámites',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_sessionId != null && !isOffline)
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: _inicializando ? null : _iniciarSesion,
              tooltip: 'Reiniciar conversación',
            ),
        ],
      ),
      body: isOffline
          ? _buildOfflineView()
          : _inicializando
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : _error.isNotEmpty
                  ? _buildErrorView()
                  : Column(
                      children: [
                        // Banner de estado/fase de conversación
                        _buildFaseBanner(),

                        // Lista de mensajes de chat
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: _mensajes.length + (_enviando ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _mensajes.length) {
                                return const _BubbleTyping();
                              }
                              return _ChatBubble(mensaje: _mensajes[i]);
                            },
                          ),
                        ),

                        // Formulario de confirmación si estamos listos para iniciar trámite
                        if (_fase == 'CONFIRMACION' || _fase == 'COMPLETADA')
                          _buildConfirmacionWidget(),

                        // Caja de entrada de texto
                        if (_fase != 'CONFIRMACION' && _fase != 'COMPLETADA')
                          _buildInputWidget(),
                      ],
                    ),
    );
  }

  Widget _buildFaseBanner() {
    String faseText = 'Fase: Identificando trámite';
    Color color = const Color(0xFF3B82F6);
    IconData icon = Icons.search;

    if (_fase == 'REQUISITOS') {
      faseText = 'Fase: Completando requisitos';
      color = const Color(0xFFF59E0B);
      icon = Icons.assignment_outlined;
    } else if (_fase == 'CONFIRMACION') {
      faseText = 'Fase: Confirmación';
      color = const Color(0xFF16A34A);
      icon = Icons.check_circle_outline;
    } else if (_fase == 'COMPLETADA') {
      faseText = 'Fase: Listo para iniciar';
      color = const Color(0xFF16A34A);
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            faseText,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_politicaNombre != null)
            Flexible(
              child: Text(
                _politicaNombre!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmacionWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Requisitos completados para:\n${_politicaNombre ?? "Trámite"}!',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_datosRecopilados.isNotEmpty) ...[
            const Text(
              'Datos recopilados por el Asistente:',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: _datosRecopilados.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                        Expanded(child: Text(e.value.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_fase == 'CONFIRMACION') ...[
            ElevatedButton.icon(
              onPressed: _enviando ? null : () {
                _inputCtrl.text = "Sí, iniciar trámite";
                _enviarMensaje();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.send, color: Colors.white),
              label: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Iniciar Trámite Ahora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
          ],
          if (_fase == 'COMPLETADA') ...[
            ElevatedButton.icon(
              onPressed: _volverPortal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text('Ir a mis trámites', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
          if (_fase != 'COMPLETADA') ...[
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Volver al Portal', style: TextStyle(color: Color(0xFF475569))),
            ),
          ],
        ],
      ),
    );
  }

  bool _grabando = false;

  Future<void> _simularGrabacion() async {
    setState(() => _grabando = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎤 Escuchando... Habla ahora.'), duration: Duration(seconds: 2)),
    );
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _grabando = false);
    _inputCtrl.text = "Quiero iniciar un trámite para solicitar vacaciones de 5 días";
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voz transcrita correctamente.'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _adjuntarArchivo() async {
    try {
      final result = await file_picker.FilePicker.platform.pickFiles();
      if (result != null) {
        final file = result.files.single;
        setState(() {
          _mensajes.add({
            'rol': 'usuario',
            'contenido': '📎 Archivo adjunto: ${file.name}',
            'timestamp': DateTime.now().toIso8601String(),
          });
        });
        _scrollToBottom();
        // Simulate assistant acknowledging the file
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            _mensajes.add({
              'rol': 'asistente',
              'contenido': 'He recibido el archivo ${file.name}. Lo he analizado y adjuntado a los requisitos.',
              'timestamp': DateTime.now().toIso8601String(),
            });
          });
          _scrollToBottom();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al adjuntar archivo')),
      );
    }
  }

  Widget _buildInputWidget() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Color(0xFF64748B)),
              onPressed: _adjuntarArchivo,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviarMensaje(),
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _simularGrabacion,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _grabando ? const Color(0xFFEF4444) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _grabando ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0)),
                ),
                child: Icon(Icons.mic, color: _grabando ? Colors.white : const Color(0xFF64748B), size: 20),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _enviarMensaje,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📴', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Asistente Desconectado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'El Asistente Inteligente IA requiere conexión activa a internet para poder procesar lenguaje natural.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver al Portal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Error de Conexión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _iniciarSesion,
              child: const Text('Reintentar Conexión'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> mensaje;
  const _ChatBubble({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esAsistente = mensaje['rol'] == 'asistente';
    final content = mensaje['contenido'] ?? '';

    return Align(
      alignment: esAsistente ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: esAsistente ? Colors.white : const Color(0xFF2563EB),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esAsistente ? 4 : 16),
            bottomRight: Radius.circular(esAsistente ? 16 : 4),
          ),
          border: esAsistente ? Border.all(color: const Color(0xFFE2E8F0)) : null,
          boxShadow: esAsistente
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          content,
          style: TextStyle(
            color: esAsistente ? const Color(0xFF1E293B) : Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _BubbleTyping extends StatelessWidget {
  const _BubbleTyping();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
            const SizedBox(width: 4),
            _dot(3),
          ],
        ),
      ),
    );
  }

  Widget _dot(int step) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + step * 150),
      builder: (_, val, __) => Transform.translate(
        offset: Offset(0, -3.0 * val),
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF94A3B8),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
