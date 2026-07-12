import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../services/app_provider.dart';
import '../../widgets/app_widgets.dart';
import '../kpi/kpi_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(Tarea) onTareaTap;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.onTareaTap,
    required this.onLogout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().cargarDatos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
        title: Consumer<AppProvider>(
          builder: (_, provider, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, ${provider.user?['nombre'] ?? ''}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                provider.user?['departamento'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (_, provider, __) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                if (provider.tareasPendientes.isNotEmpty)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${provider.tareasPendientes.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AppProvider>().logout();
              widget.onLogout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: '🔴 Pendientes'),
            Tab(text: '🟡 En Proceso'),
            Tab(text: '🟢 Listas'),
            Tab(text: '📈 KPIs'),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (_, provider, __) {
          if (provider.loadingData) return const LoadingWidget();

          return Column(
            children: [
              _buildStats(provider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                     _buildLista(provider.tareasPendientes, 'No tienes tareas pendientes'),
                     _buildLista(provider.tareasEnProceso, 'No tienes tareas en proceso'),
                     _buildLista(provider.tareasCompletadas, 'No tienes tareas completadas'),
                     const KpiScreen(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () => context.read<AppProvider>().cargarDatos(),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildStats(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          _buildStatChip('Total', '${provider.tareas.length}', const Color(0xFF3B82F6), Icons.folder_copy_outlined),
          const SizedBox(width: 12),
          _buildStatChip('Pendientes', '${provider.tareasPendientes.length}', const Color(0xFFEF4444), Icons.pending_actions),
          const SizedBox(width: 12),
          _buildStatChip('Completadas', '${provider.tareasCompletadas.length}', const Color(0xFF22C55E), Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String valor, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(valor, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLista(List<Tarea> tareas, String mensajeVacio) {
    if (tareas.isEmpty) return EmptyWidget(mensaje: mensajeVacio);
    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      onRefresh: () => context.read<AppProvider>().cargarDatos(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tareas.length,
        itemBuilder: (_, i) => TareaCard(
          tarea: tareas[i],
          onTap: () => widget.onTareaTap(tareas[i]),
        ),
      ),
    );
  }
}