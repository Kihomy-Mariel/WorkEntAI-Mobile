import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../kpi/kpi_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminDashboardScreen({super.key, required this.onLogout});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Darker premium gradient for Admin
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 6,
        shadowColor: Colors.black45,
        title: Consumer<AppProvider>(
          builder: (_, provider, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Panel de Administración',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '${provider.user?['nombre'] ?? 'Administrador'}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración del sistema')));
            },
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
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
            Tab(icon: Icon(Icons.insights), text: 'KPIs'),
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Cuellos Botella'),
            Tab(icon: Icon(Icons.description), text: 'Políticas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResumenTab(),
          const KpiScreen(), // We reuse the existing KPI screen
          _buildUsuariosTab(),
          _buildAnomaliasTab(),
          _buildPoliticasTab(),
        ],
      ),
    );
  }

  // ── 1. Resumen Tab ──────────────────────────────────────────────────────────
  Widget _buildResumenTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Métricas Generales',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('Trámites Totales', '1,284', Icons.folder, const Color(0xFF3B82F6)),
            const SizedBox(width: 12),
            _buildStatCard('Usuarios Activos', '14', Icons.people, const Color(0xFF10B981)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('Cuellos Detectados', '3', Icons.warning, const Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            _buildStatCard('Tasa Éxito', '98%', Icons.trending_up, const Color(0xFF8B5CF6)),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Actividad Reciente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 12),
        _buildActivityRow('Nuevo trámite iniciado por Empresa ABC', 'Hace 5 min', Icons.add_circle, Colors.blue),
        _buildActivityRow('Cuello de botella resuelto en Finanzas', 'Hace 2 horas', Icons.check_circle, Colors.green),
        _buildActivityRow('Funcionario Ana López completó 5 tareas', 'Hace 4 horas', Icons.person, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(String text, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
                Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Usuarios Tab ─────────────────────────────────────────────────────────
  Widget _buildUsuariosTab() {
    final users = [
      {'nombre': 'Carlos Mendoza', 'rol': 'ADMIN', 'email': 'admin@workent.com', 'activo': true},
      {'nombre': 'Juan Pérez', 'rol': 'FUNCIONARIO', 'email': 'atencionalcliente@workent.com', 'activo': true},
      {'nombre': 'Ana López', 'rol': 'FUNCIONARIO', 'email': 'tecnico@workent.com', 'activo': true},
      {'nombre': 'María Torres', 'rol': 'FUNCIONARIO', 'email': 'legal@workent.com', 'activo': true},
      {'nombre': 'Empresa ABC S.R.L.', 'rol': 'CLIENTE', 'email': 'cliente1@correo.com', 'activo': true},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (ctx, i) {
        final u = users[i];
        final isFunc = u['rol'] == 'FUNCIONARIO';
        final isAdmin = u['rol'] == 'ADMIN';
        final color = isAdmin ? Colors.purple : (isFunc ? Colors.blue : Colors.orange);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(Icons.person, color: color),
            ),
            title: Text(u['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${u['rol']} • ${u['email']}', style: const TextStyle(fontSize: 12)),
            trailing: Switch(
              value: u['activo'] as bool,
              onChanged: (v) {},
              activeColor: Colors.green,
            ),
          ),
        );
      },
    );
  }

  // ── 3. Análisis de Cuellos de Botella (LSTM Mock) ─────────────────────────
  Widget _buildAnomaliasTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_graph, color: Color(0xFFD97706), size: 32),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Motor de IA Analítico', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    Text('Analizando tiempos de ejecución mediante LSTM.', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildAnomaliaCard('Trámite de Importación', 'Departamento Legal', '3 días retraso', 0.85),
        _buildAnomaliaCard('Solicitud de Vacaciones', 'Departamento Finanzas', '1 día retraso', 0.65),
      ],
    );
  }

  Widget _buildAnomaliaCard(String tramite, String depto, String retraso, double conf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 8),
                Text('Cuello de botella detectado', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            Text(tramite, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Atascado en: $depto', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                  child: Text(retraso, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Text('Confianza IA: ${(conf * 100).toInt()}%', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.flash_on, color: Colors.white, size: 16),
                label: const Text('Reasignar tareas', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Políticas Tab ────────────────────────────────────────────────────────
  Widget _buildPoliticasTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_tree_outlined, size: 64, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text('Políticas y Trámites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          const Text('Administra los flujos de trabajo desde la versión Web.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
            child: const Text('Sincronizar Políticas', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
