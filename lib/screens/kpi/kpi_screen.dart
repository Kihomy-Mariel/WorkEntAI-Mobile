import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../services/app_provider.dart';

/// Pantalla de KPIs personales del funcionario.
/// Principio SRP: solo muestra métricas, no gestiona lógica de negocio.
class KpiScreen extends StatelessWidget {
  const KpiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConfig.bgColor),
      appBar: AppBar(
        backgroundColor: const Color(AppConfig.cardColor),
        elevation: 0,
        title: const Text('📈 Mis KPIs', style: TextStyle(fontSize: 16)),
      ),
      body: Consumer<AppProvider>(
        builder: (_, provider, __) {
          final tareas = provider.tareas;
          final completadas = provider.tareasCompletadas;
          final pendientes = provider.tareasPendientes;
          final enProceso = provider.tareasEnProceso;

          final tasaCompletado = tareas.isEmpty
              ? 0.0
              : (completadas.length / tareas.length) * 100;

          // Promedio de duración de tareas completadas
          final tareasConDuracion = completadas
              .where((t) => t.duracionMinutos != null)
              .toList();
          final promedioDuracion = tareasConDuracion.isEmpty
              ? 0
              : tareasConDuracion
                      .map((t) => t.duracionMinutos!)
                      .reduce((a, b) => a + b) ~/
                  tareasConDuracion.length;

          return RefreshIndicator(
            color: const Color(AppConfig.accentColor),
            onRefresh: () => provider.cargarDatos(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Resumen general
                _buildSectionTitle('Resumen General'),
                const SizedBox(height: 12),
                _buildKpiGrid([
                  _KpiItem('Total Tareas', '${tareas.length}',
                      const Color(0xFF3B82F6), Icons.task_alt),
                  _KpiItem('Completadas', '${completadas.length}',
                      const Color(0xFF22C55E), Icons.check_circle_outline),
                  _KpiItem('Pendientes', '${pendientes.length}',
                      const Color(0xFFEF4444), Icons.pending_actions),
                  _KpiItem('En Proceso', '${enProceso.length}',
                      const Color(0xFFF59E0B), Icons.hourglass_empty),
                ]),
                const SizedBox(height: 20),

                // Eficiencia
                _buildSectionTitle('Eficiencia'),
                const SizedBox(height: 12),
                _buildKpiGrid([
                  _KpiItem('Tasa Completado',
                      '${tasaCompletado.toStringAsFixed(1)}%',
                      const Color(0xFF22C55E), Icons.trending_up),
                  _KpiItem('Prom. Duración',
                      promedioDuracion > 0 ? '${promedioDuracion}min' : '—',
                      const Color(0xFF8B5CF6), Icons.timer_outlined),
                ]),
                const SizedBox(height: 20),

                // Barra de progreso visual
                _buildSectionTitle('Progreso de Tareas'),
                const SizedBox(height: 12),
                _buildProgressCard(
                  completadas: completadas.length,
                  enProceso: enProceso.length,
                  pendientes: pendientes.length,
                  total: tareas.length,
                ),
                const SizedBox(height: 20),

                // Últimas completadas
                if (completadas.isNotEmpty) ...[
                  _buildSectionTitle('Últimas Completadas'),
                  const SizedBox(height: 12),
                  ...completadas.take(5).map((t) => _buildTareaRow(t)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      );

  Widget _buildKpiGrid(List<_KpiItem> items) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: items.map(_buildKpiCard).toList(),
      );

  Widget _buildKpiCard(_KpiItem item) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(AppConfig.cardColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(item.icon, color: item.color, size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.valor,
                    style: TextStyle(
                        color: item.color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(item.label,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
      );

  Widget _buildProgressCard({
    required int completadas,
    required int enProceso,
    required int pendientes,
    required int total,
  }) {
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(AppConfig.cardColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Sin tareas aún',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConfig.cardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                _buildProgressSegment(
                    completadas / total, const Color(0xFF22C55E)),
                _buildProgressSegment(
                    enProceso / total, const Color(0xFFF59E0B)),
                _buildProgressSegment(
                    pendientes / total, const Color(0xFFEF4444)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegend('Completadas', const Color(0xFF22C55E)),
              _buildLegend('En Proceso', const Color(0xFFF59E0B)),
              _buildLegend('Pendientes', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSegment(double ratio, Color color) => Expanded(
        flex: (ratio * 100).round().clamp(0, 100),
        child: Container(height: 12, color: color),
      );

  Widget _buildLegend(String label, Color color) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      );

  Widget _buildTareaRow(tarea) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(AppConfig.cardColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Text('🟢', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tarea.nombreNodo ?? tarea.nodoId,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (tarea.duracionMinutos != null)
              Text('${tarea.duracionMinutos}min',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      );
}

class _KpiItem {
  final String label;
  final String valor;
  final Color color;
  final IconData icon;

  const _KpiItem(this.label, this.valor, this.color, this.icon);
}
