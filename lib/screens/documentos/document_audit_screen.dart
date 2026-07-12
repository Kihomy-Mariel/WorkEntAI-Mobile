import 'package:flutter/material.dart';
import '../../services/documento_service.dart';

class DocumentAuditScreen extends StatefulWidget {
  final String tramiteId;

  const DocumentAuditScreen({Key? key, required this.tramiteId}) : super(key: key);

  @override
  _DocumentAuditScreenState createState() => _DocumentAuditScreenState();
}

class _DocumentAuditScreenState extends State<DocumentAuditScreen> {
  final DocumentoService _documentoService = DocumentoService();
  bool _isLoading = true;
  List<dynamic> _auditoria = [];

  @override
  void initState() {
    super.initState();
    _loadAuditoria();
  }

  Future<void> _loadAuditoria() async {
    setState(() => _isLoading = true);
    try {
      final aud = await _documentoService.obtenerAuditoriaTramite(widget.tramiteId);
      setState(() {
        _auditoria = aud;
      });
    } catch (e) {
      _showError('Error al cargar auditoría: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
    ));
  }

  Color _getActionColor(String accion) {
    switch (accion) {
      case 'SUBIR': return Colors.green;
      case 'VER_URL': return Colors.blue;
      case 'ELIMINAR': return Colors.red;
      case 'CAMBIAR_PERMISOS': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getActionIcon(String accion) {
    switch (accion) {
      case 'SUBIR': return Icons.upload_file;
      case 'VER_URL': return Icons.visibility;
      case 'ELIMINAR': return Icons.delete;
      case 'CAMBIAR_PERMISOS': return Icons.admin_panel_settings;
      default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Auditoría Documental', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _auditoria.isEmpty
              ? _buildEmptyState()
              : _buildTimeline(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay registros de auditoría',
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _auditoria.length,
      itemBuilder: (context, index) {
        final item = _auditoria[index];
        final isLast = index == _auditoria.length - 1;
        final actionColor = _getActionColor(item['accion'] ?? '');

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline line and dot
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: actionColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: actionColor, width: 2),
                      ),
                      child: Icon(_getActionIcon(item['accion'] ?? ''), size: 16, color: actionColor),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['accion'] ?? 'ACCIÓN',
                                style: TextStyle(fontWeight: FontWeight.bold, color: actionColor, fontSize: 14),
                              ),
                              Text(
                                // Format datetime logic
                                item['timestamp']?.split('T')?[0] ?? '',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['detalle'] ?? '',
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${item['usuarioNombre']} (${item['rolUsuario']})',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
