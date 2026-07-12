import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/documento_service.dart';
import '../../services/auth_service.dart';
import 'document_audit_screen.dart';
import 'collaborative_editor_screen.dart';

class DocumentRepositoryScreen extends StatefulWidget {
  final String tramiteId;

  const DocumentRepositoryScreen({Key? key, required this.tramiteId}) : super(key: key);

  @override
  _DocumentRepositoryScreenState createState() => _DocumentRepositoryScreenState();
}

class _DocumentRepositoryScreenState extends State<DocumentRepositoryScreen> {
  final DocumentoService _documentoService = DocumentoService();
  bool _isLoading = true;
  List<dynamic> _documentos = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadDocumentos();
  }

  Future<void> _loadDocumentos() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _documentoService.listarDocumentos(widget.tramiteId);
      setState(() {
        _documentos = docs;
      });
    } catch (e) {
      _showError('Error al cargar documentos: $e');
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

  Widget _buildDocIcon(String mimeType) {
    IconData icon;
    Color color;
    if (mimeType.contains('pdf')) {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (mimeType.contains('image')) {
      icon = Icons.image;
      color = Colors.blue;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      icon = Icons.description;
      color = Colors.blueAccent;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final esAdmin = authService.currentUser?.rol == 'ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Repositorio Documental', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Auditoría',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => DocumentAuditScreen(tramiteId: widget.tramiteId),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_document),
            tooltip: 'Notas Colaborativas',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CollaborativeEditorScreen(docId: '${widget.tramiteId}-notas'),
              ));
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documentos.isEmpty
              ? _buildEmptyState()
              : _buildDocsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : () => _showUploadDialog(),
        backgroundColor: Colors.blueAccent,
        icon: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.upload_file),
        label: const Text('Subir Doc'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aún no hay documentos en este trámite',
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDocsList() {
    return RefreshIndicator(
      onRefresh: _loadDocumentos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _documentos.length,
        itemBuilder: (context, index) {
          final doc = _documentos[index];
          return Card(
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: _buildDocIcon(doc['tipoMime'] ?? ''),
              title: Text(
                doc['nombre'] ?? 'Documento',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subido por: ${doc['subidoPorNombre']}'),
                    const SizedBox(height: 4),
                    Text('Versión: ${doc['version']} • ${(doc['tamanoBytes'] / 1024).toStringAsFixed(1)} KB'),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download, color: Colors.blueAccent),
                onPressed: () => _showError('Descarga no implementada en la demo'), // Simulate download
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUploadDialog() {
    // In a real app we'd use file_picker. For this demo we'll show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subir Archivo'),
        content: const Text('La selección de archivos requiere el plugin file_picker. Esta es una simulación visual.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showError('Simulación: Archivo subido correctamente (UI Mock)');
            },
            child: const Text('Simular Subida'),
          ),
        ],
      ),
    );
  }
}
