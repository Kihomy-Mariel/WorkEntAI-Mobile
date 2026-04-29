import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/app_provider.dart';

class TramiteDetalleScreen extends StatefulWidget {
  final Tramite tramite;
  const TramiteDetalleScreen({super.key, required this.tramite});

  @override
  State<TramiteDetalleScreen> createState() => _TramiteDetalleScreenState();
}

class _TramiteDetalleScreenState extends State<TramiteDetalleScreen> {
  late Tramite _tramite;
  bool _loadingPdf = false;
  bool _refreshing = false;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tramite = widget.tramite;
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final updated =
        await context.read<AppProvider>().refreshTramite(_tramite.id);
    if (updated != null && mounted) {
      setState(() {
        _tramite = updated;
        _refreshing = false;
      });
    } else {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _descargarPdf() async {
    setState(() => _loadingPdf = true);
    try {
      // 1. Pedir permiso de almacenamiento en Android < 13
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        // En Android 13+ el permiso de storage ya no es necesario para Downloads
        // Si se deniega en versiones anteriores, continuamos de todas formas
        // porque usaremos MediaStore o la ruta directa
        if (status.isPermanentlyDenied) {
          if (mounted) {
            _showSnackBar(
              '⚠️ Permiso denegado. Ve a Ajustes > Permisos para habilitarlo.',
              isError: true,
            );
          }
          setState(() => _loadingPdf = false);
          return;
        }
      }

      // 2. Descargar bytes del PDF
      final bytes = await _apiService.descargarPdf(_tramite.id);
      final fileName = 'tramite-${_tramite.refDisplay}.pdf';

      // 3. Guardar en Downloads
      final filePath = await _guardarEnDownloads(bytes, fileName);

      if (!mounted) return;
      setState(() => _loadingPdf = false);

      // 4. Snackbar con botón "ABRIR"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✅ PDF guardado en Descargas',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                fileName,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'ABRIR',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(filePath),
          ),
        ),
      );
    } catch (e) {
      setState(() => _loadingPdf = false);
      if (mounted) {
        _showSnackBar(
          '❌ Error: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true,
        );
      }
    }
  }

  /// Guarda el PDF en la carpeta Downloads del dispositivo.
  Future<String> _guardarEnDownloads(List<int> bytes, String fileName) async {
    String filePath;

    if (Platform.isAndroid) {
      // Intentar la carpeta Downloads estándar de Android
      const downloadsPath = '/storage/emulated/0/Download';
      final downloadsDir = Directory(downloadsPath);

      if (await downloadsDir.exists()) {
        filePath = '$downloadsPath/$fileName';
      } else {
        // Fallback: directorio externo de la app (visible en Archivos)
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          filePath = '${extDir.path}/$fileName';
        } else {
          // Último fallback: documentos de la app
          final docDir = await getApplicationDocumentsDirectory();
          filePath = '${docDir.path}/$fileName';
        }
      }
    } else if (Platform.isIOS) {
      // iOS: Documents directory (visible en la app Archivos)
      final docDir = await getApplicationDocumentsDirectory();
      filePath = '${docDir.path}/$fileName';
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      filePath = '${docDir.path}/$fileName';
    }

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tramite.refDisplay,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'monospace',
              ),
            ),
            Text(
              _tramite.nombrePolitica ?? 'Trámite',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2563EB),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: _refresh,
              tooltip: 'Actualizar',
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2563EB),
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Estado card ───────────────────────────────
              _buildEstadoCard(),
              const SizedBox(height: 16),

              // ── Tracker de progreso ───────────────────────
              _buildTrackerCard(),
              const SizedBox(height: 16),

              // ── Info general ──────────────────────────────
              _buildInfoCard(),
              const SizedBox(height: 16),

              // ── Datos formulario (si completado) ──────────
              if (_tramite.estado == 'COMPLETADO' &&
                  _tramite.datosFormulario != null &&
                  _tramite.datosFormulario!.isNotEmpty) ...[
                _buildDatosCard(),
                const SizedBox(height: 16),
              ],

              // ── Botón PDF ─────────────────────────────────
              if (_tramite.estado == 'COMPLETADO') _buildPdfButton(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _tramite.estadoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _tramite.estadoEmoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tramite.estadoLabel,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _tramite.estadoColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _getEstadoDescripcion(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEstadoDescripcion() {
    switch (_tramite.estado) {
      case 'NUEVO':
        return 'Tu solicitud fue recibida. El administrador la revisará pronto.';
      case 'EN_PROCESO':
        return 'Tu trámite está siendo procesado en ${_tramite.departamentoActual ?? 'un departamento'}.';
      case 'COMPLETADO':
        return 'Tu trámite fue completado exitosamente. Puedes descargar el comprobante.';
      case 'RECHAZADO':
        return 'Tu trámite fue rechazado. Contáctanos para más información.';
      default:
        return '';
    }
  }

  Widget _buildTrackerCard() {
    final pasos = _buildPasos();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route_outlined, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Progreso del Trámite',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pasos.isEmpty)
            const Text(
              'El trámite aún no ha iniciado.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            )
          else
            ...pasos.asMap().entries.map((entry) {
              final i = entry.key;
              final paso = entry.value;
              return _buildTrackerItem(paso, i == pasos.length - 1);
            }),
        ],
      ),
    );
  }

  List<_PasoTracker> _buildPasos() {
    final pasos = <_PasoTracker>[];

    // Pasos completados del historial
    for (final h in _tramite.historial) {
      pasos.add(_PasoTracker(
        nombre: h.nombreNodo,
        departamento: h.departamento,
        fecha: h.fechaFormatted,
        completado: true,
        actual: false,
        observacion: h.observacion,
        resultado: h.resultadoDecision,
        duracion: h.duracionMinutos,
      ));
    }

    // Paso actual (si en proceso)
    if (_tramite.estado == 'EN_PROCESO' &&
        _tramite.nombreNodoActual != null) {
      pasos.add(_PasoTracker(
        nombre: _tramite.nombreNodoActual!,
        departamento: _tramite.departamentoActual,
        fecha: null,
        completado: false,
        actual: true,
      ));
    }

    return pasos;
  }

  Widget _buildTrackerItem(_PasoTracker paso, bool isLast) {
    final color = paso.completado
        ? const Color(0xFF22C55E)
        : paso.actual
            ? const Color(0xFFF59E0B)
            : const Color(0xFFCBD5E1);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea + círculo
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: paso.completado
                        ? Icon(Icons.check, size: 14, color: color)
                        : paso.actual
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: paso.completado
                          ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paso.nombre,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: paso.actual
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  if (paso.departamento != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.business_outlined,
                            size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Text(
                          paso.departamento!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (paso.fecha != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined,
                            size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Text(
                          paso.fecha!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        if (paso.duracion != null) ...[
                          const Text(' · ',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 11)),
                          Text(
                            '${paso.duracion}min',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (paso.resultado != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: paso.resultado == 'APROBADO'
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        paso.resultado == 'APROBADO'
                            ? '✅ Aprobado'
                            : '❌ Rechazado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: paso.resultado == 'APROBADO'
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                  if (paso.observacion != null &&
                      paso.observacion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      paso.observacion!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (paso.actual) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Text(
                        '⏳ En proceso...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Información General',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Referencia', _tramite.refDisplay),
          _buildInfoRow('Política', _tramite.nombrePolitica ?? '—'),
          if (_tramite.descripcion != null && _tramite.descripcion!.isNotEmpty)
            _buildInfoRow('Descripción', _tramite.descripcion!),
          _buildInfoRow('Prioridad', _tramite.prioridad ?? 'MEDIA'),
          _buildInfoRow('Fecha inicio', _tramite.fechaInicioFormatted),
          if (_tramite.fechaFinFormatted != null)
            _buildInfoRow('Fecha fin', _tramite.fechaFinFormatted!),
          if (_tramite.duracionMinutos != null)
            _buildInfoRow('Duración total', _tramite.duracionFormatted),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosCard() {
    final datos = _tramite.datosFormulario!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Datos Recopilados',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...datos.entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${e.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPdfButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _loadingPdf ? null : _descargarPdf,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _loadingPdf
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.picture_as_pdf_outlined, size: 20),
        label: Text(
          _loadingPdf ? 'Generando PDF...' : 'Descargar Comprobante PDF',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _PasoTracker {
  final String nombre;
  final String? departamento;
  final String? fecha;
  final bool completado;
  final bool actual;
  final String? observacion;
  final String? resultado;
  final int? duracion;

  _PasoTracker({
    required this.nombre,
    this.departamento,
    this.fecha,
    required this.completado,
    required this.actual,
    this.observacion,
    this.resultado,
    this.duracion,
  });
}
