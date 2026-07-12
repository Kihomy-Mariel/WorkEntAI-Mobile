import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../services/notification_service.dart';
import '../cliente_portal/cliente_portal_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../perfil/perfil_screen.dart';
import '../login/login_screen.dart';
import '../tramite_detalle/tramite_detalle_screen.dart';

import '../dashboard/dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../tarea_detalle/tarea_detalle_screen.dart';

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
      // Registrar handler de navegación para notificaciones push (CU-14)
      _registrarNavHandler();
    });
  }

  void _registrarNavHandler() {
    NotificationService.setNavigationHandler((tipo, referenciaId) {
      if (!mounted) return;
      switch (tipo) {
        case 'NUEVA_TAREA':
        case 'TAREA_ASIGNADA':
          // Ir a la pestaña de notificaciones para que el usuario vea la nueva tarea
          setState(() => _currentIndex = 1);
          break;
        case 'TRAMITE_COMPLETADO':
        case 'TRAMITE_ACTUALIZADO':
        case 'TAREA_COMPLETADA':
          // Navegar al detalle del trámite si tenemos el ID
          if (referenciaId.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TramiteDetalleScreen.byId(tramiteId: referenciaId),
              ),
            );
          }
          break;
        default:
          // Ir a notificaciones como fallback
          setState(() => _currentIndex = 1);
      }
    });
  }

  @override
  void dispose() {
    // Limpiar handler al salir para evitar memory leaks
    NotificationService.clearNavigationHandler();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, provider, __) {
        final rol = provider.userRol;
        if (rol == 'ADMIN') {
          return AdminDashboardScreen(
            onLogout: () async {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          );
        }

        if (rol == 'FUNCIONARIO') {
          return DashboardScreen(
            onTareaTap: (tarea) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TareaDetalleScreen(
                    tarea: tarea,
                    onCompletado: () {
                      Navigator.pop(context); // Regresar al dashboard
                      context.read<AppProvider>().cargarDatos(); // Recargar las tareas
                    },
                  ),
                ),
              );
            },
            onLogout: () async {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          );
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
}
