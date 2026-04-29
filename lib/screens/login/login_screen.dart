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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Color(0xFF0369A1)),
                          SizedBox(width: 6),
                          Text(
                            'Cuentas de demostración',
                            style: TextStyle(
                              color: Color(0xFF0369A1),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildTestBtn(
                          '👤 Cliente', 'cliente@workflow.com'),
                      _buildTestBtn(
                          '🏥 Hospital', 'hospital@workflow.com'),
                      _buildTestBtn(
                          '🏗️ Constructora', 'constructora@workflow.com'),
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

  Widget _buildTestBtn(String label, String email) {
    return GestureDetector(
      onTap: () => _fillAccount(email),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0369A1),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              ' → ',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            Text(
              email,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
