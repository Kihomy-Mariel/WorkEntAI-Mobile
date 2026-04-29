import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../cliente_portal/cliente_portal_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../perfil/perfil_screen.dart';
import '../login/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().cargarDatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        // Solo cliente usa este home con bottom nav
        // Funcionarios/Admin van directo a su pantalla
        final rol = provider.userRol;
        if (rol != 'CLIENTE' && rol.isNotEmpty) {
          // Para funcionarios/admin, mostrar solo sus tareas
          return _buildFuncionarioHome(provider);
        }

        final pages = [
          const ClientePortalScreen(),
          const NotificacionesScreen(),
          const PerfilScreen(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF2563EB),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              elevation: 0,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Trámites',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined),
                      if (provider.unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${provider.unreadCount > 9 ? '9+' : provider.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications),
                      if (provider.unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${provider.unreadCount > 9 ? '9+' : provider.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Notificaciones',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFuncionarioHome(AppProvider provider) {
    // Pantalla simple para funcionarios en mobile
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.userNombre,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(provider.userDepartamento,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              await provider.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💼', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Panel de Funcionario',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Accede al panel completo desde\nla aplicación web en tu computadora.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  '🌐 http://localhost:4200',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
