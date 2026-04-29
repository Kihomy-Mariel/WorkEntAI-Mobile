import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/models.dart';

// ── Tarjeta de Tarea ──────────────────────────────────────────
class TareaCard extends StatelessWidget {
  final Tarea tarea;
  final VoidCallback onTap;

  const TareaCard({super.key, required this.tarea, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(AppConfig.cardColor),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: tarea.estadoColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              // CORREGIDO: withOpacity reemplazado por withValues
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8, offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    // CORREGIDO: withOpacity reemplazado por withValues
                    color: tarea.estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tarea.estadoLabel,
                    style: TextStyle(
                      color: tarea.estadoColor,
                      fontSize: 11, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatFecha(tarea.fechaAsignacion),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Nodo: ${tarea.nodoId}',
              style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Trámite: ${tarea.tramiteId.substring(0, 12)}...',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConfig.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Ver Tarea →', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha.substring(0, 10);
    }
  }
}

// ── Indicador de carga ────────────────────────────────────────
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(AppConfig.accentColor),
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────
class EmptyWidget extends StatelessWidget {
  final String mensaje;
  const EmptyWidget({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Badge de estado ───────────────────────────────────────────
class EstadoBadge extends StatelessWidget {
  final String estado;
  const EstadoBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (estado) {
      case 'NUEVO':
        color = const Color(0xFFEF4444); label = '🔴 Nuevo';
      case 'EN_PROCESO':
        color = const Color(0xFFF59E0B); label = '🟡 En Proceso';
      case 'COMPLETADO':
        color = const Color(0xFF22C55E); label = '🟢 Completado';
      default:
        color = Colors.grey; label = estado;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        // CORREGIDO: withOpacity reemplazado por withValues
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        // CORREGIDO: withOpacity reemplazado por withValues
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}