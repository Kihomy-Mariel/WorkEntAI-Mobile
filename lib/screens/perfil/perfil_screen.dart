import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../login/login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nombreCtrl = TextEditingController();
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _nombreCtrl.text = provider.userNombre;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final provider = context.read<AppProvider>();
    final ok = await provider.updatePerfil(
      _nombreCtrl.text.trim(),
      provider.userDepartamento,
    );
    if (mounted) {
      setState(() => _editando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '✅ Perfil actualizado' : '❌ ${provider.actionError}'),
          backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final provider = context.read<AppProvider>();
      await provider.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (_editando)
            TextButton(
              onPressed: () => setState(() {
                _editando = false;
                _nombreCtrl.text = context.read<AppProvider>().userNombre;
              }),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF64748B))),
            ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (_, provider, __) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Avatar ────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            provider.userNombre.isNotEmpty
                                ? provider.userNombre[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        provider.userNombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          provider.userRol,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Info card ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Información Personal',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (!_editando)
                            GestureDetector(
                              onTap: () => setState(() => _editando = true),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 16, color: Color(0xFF2563EB)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Editar',
                                    style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      const Text(
                        'Nombre completo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _editando
                          ? TextField(
                              controller: _nombreCtrl,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Tu nombre completo',
                              ),
                            )
                          : Text(
                              provider.userNombre,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                      const SizedBox(height: 14),

                      // Email
                      const Text(
                        'Correo electrónico',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        provider.userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),

                      if (_editando) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: Consumer<AppProvider>(
                            builder: (_, p, __) => ElevatedButton(
                              onPressed: p.loadingAction ? null : _guardar,
                              child: p.loadingAction
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Guardar cambios'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stats ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mis Trámites',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildStatItem(
                            '${provider.tramites.length}',
                            'Total',
                            const Color(0xFF2563EB),
                          ),
                          _buildStatItem(
                            '${provider.tramitesActivos.length}',
                            'Activos',
                            const Color(0xFFF59E0B),
                          ),
                          _buildStatItem(
                            '${provider.tramitesCompletados.length}',
                            'Completados',
                            const Color(0xFF22C55E),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Cerrar sesión ─────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_outlined, size: 18),
                    label: const Text('Cerrar Sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'WorkEntAI v1.0.0',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
