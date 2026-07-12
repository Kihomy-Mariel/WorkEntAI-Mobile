import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    provider.clearErrors();
    final ok = await provider.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _fillAccount(String email) {
    setState(() {
      _emailCtrl.text = email;
      _passCtrl.text = '123456';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 56),

                // ── Logo ──────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('⚡', style: TextStyle(fontSize: 38)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'WorkEntAI',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Portal de Trámites',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Card login ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email
                      const Text(
                        'Correo electrónico',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'usuario@empresa.com',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu correo';
                          if (!v.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      const Text(
                        'Contraseña',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                          if (v.length < 4) return 'Contraseña muy corta';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Error
                      Consumer<AppProvider>(
                        builder: (_, p, __) => p.authError.isNotEmpty
                            ? Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Color(0xFFEF4444), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        p.authError,
                                        style: const TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(),
                      ),

                      // Botón
                      Consumer<AppProvider>(
                        builder: (_, p, __) => SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: p.loadingAuth ? null : _login,
                            child: p.loadingAuth
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Ingresar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Cuentas de prueba ─────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 18, color: Color(0xFF0369A1)),
                          SizedBox(width: 8),
                          Text(
                            'Modo Desarrollo',
                            style: TextStyle(
                              color: Color(0xFF0369A1),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0369A1),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFBAE6FD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.list_alt, size: 18),
                        label: const Text('Ver Usuarios de Prueba'),
                        onPressed: _mostrarUsuariosDemo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final List<Map<String, String>> _demoUsers = [
    {'rol': '👑 ADMIN', 'nombre': 'Administrador Principal', 'email': 'admin@workent.com'},
    {'rol': '💼 FUNCIONARIO', 'nombre': 'Atención al Cliente', 'email': 'atencionalcliente@workent.com'},
    {'rol': '💼 FUNCIONARIO', 'nombre': 'Técnico', 'email': 'tecnico@workent.com'},
    {'rol': '💼 FUNCIONARIO', 'nombre': 'Legal', 'email': 'legal@workent.com'},
    {'rol': '💼 FUNCIONARIO', 'nombre': 'Almacén', 'email': 'almacen@workent.com'},
    {'rol': '💼 FUNCIONARIO', 'nombre': 'Finanzas', 'email': 'finanzas@workent.com'},
    {'rol': '👤 CLIENTE', 'nombre': 'Juan Perez', 'email': 'cliente1@correo.com'},
    {'rol': '👤 CLIENTE', 'nombre': 'Maria Lopez', 'email': 'cliente2@correo.com'},
    {'rol': '👤 CLIENTE', 'nombre': 'Carlos Ramirez', 'email': 'cliente3@correo.com'},
    {'rol': '👤 CLIENTE', 'nombre': 'Ana Torres', 'email': 'cliente4@correo.com'},
    {'rol': '👤 CLIENTE', 'nombre': 'Luis Gomez', 'email': 'cliente5@correo.com'},
    {'rol': '👤 CLIENTE', 'nombre': 'Sofia Vargas', 'email': 'cliente6@correo.com'},
  ];

  void _mostrarUsuariosDemo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              const Text(
                'Seleccionar Usuario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _demoUsers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = _demoUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Text(
                          u['rol']!.split(' ')[0],
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      title: Text(
                        u['nombre']!,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${u['rol']!.split(' ')[1]} • ${u['email']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _fillAccountAndLogin(u['email']!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _fillAccountAndLogin(String email) {
    setState(() {
      _emailCtrl.text = email;
      _passCtrl.text = '123456';
    });
    // Iniciar sesión automáticamente después de llenar los campos
    Future.delayed(const Duration(milliseconds: 100), () {
      _login();
    });
  }
}
