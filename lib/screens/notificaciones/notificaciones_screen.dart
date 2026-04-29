import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_provider.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          Consumer<AppProvider>(
            builder: (_, p, __) => p.notificaciones.isNotEmpty
                ? TextButton(
                    onPressed: () => p.marcarTodasLeidas(),
                    child: const Text(
                      'Marcar leídas',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 13,
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (_, provider, __) {
          if (provider.loadingData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            );
          }

          final notifs = provider.notificaciones;

          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  const Text(
                    'Sin notificaciones',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aquí aparecerán las actualizaciones\nde tus trámites.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => provider.cargarNotificaciones(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Actualizar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF2563EB),
            onRefresh: () => provider.cargarNotificaciones(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              itemBuilder: (_, i) => _NotifCard(
                notif: notifs[i],
                onTap: () => provider.marcarLeida(notifs[i].id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final Notificacion notif;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.leida ? Colors.white : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.leida
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono tipo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  notif.tipoEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.mensaje,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF1E293B),
                      fontWeight:
                          notif.leida ? FontWeight.normal : FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.fechaFormatted,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Indicador no leída
            if (!notif.leida) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColor() {
    switch (notif.tipo) {
      case 'TRAMITE_COMPLETADO':
        return const Color(0xFF22C55E);
      case 'TRAMITE_RECHAZADO':
        return const Color(0xFFEF4444);
      case 'TRAMITE_AVANZADO':
        return const Color(0xFF2563EB);
      case 'CUELLO_BOTELLA':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF2563EB);
    }
  }
}
