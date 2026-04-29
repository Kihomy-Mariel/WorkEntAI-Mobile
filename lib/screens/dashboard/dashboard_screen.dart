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
      backgroundColor: const Color(AppConfig.bgColor),
      appBar: AppBar(
        backgroundColor: const Color(AppConfig.cardColor),
        elevation: 0,
        title: Consumer<AppProvider>(
          builder: (_, provider, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, ${provider.user?['nombre'] ?? ''}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                provider.user?['departamento'] ?? '',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (_, provider, __) => Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                if (provider.tareasPendientes.isNotEmpty)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${provider.tareasPendientes.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await context.read<AppProvider>().logout();
              widget.onLogout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(AppConfig.accentColor),
          labelColor: const Color(AppConfig.accentColor),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
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
        backgroundColor: const Color(AppConfig.primaryColor),
        onPressed: () => context.read<AppProvider>().cargarDatos(),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildStats(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(AppConfig.cardColor).withValues(alpha: 0.5),
      child: Row(
        children: [
          _buildStatChip('Total', '${provider.tareas.length}', Colors.white),
          const SizedBox(width: 8),
          _buildStatChip('Pendientes', '${provider.tareasPendientes.length}', const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          _buildStatChip('Completadas', '${provider.tareasCompletadas.length}', const Color(0xFF22C55E)),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(valor, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildLista(List<Tarea> tareas, String mensajeVacio) {
    if (tareas.isEmpty) return EmptyWidget(mensaje: mensajeVacio);
    return RefreshIndicator(
      color: const Color(AppConfig.accentColor),
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