import 'package:flutter/material.dart';
import 'package:uni_escom/services/student/home_screen.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscure = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty) {
      _showSnack("Ingresa tu correo institucional");
      return false;
    }
    if (!email.contains("@")) {
      _showSnack("El correo no parece válido");
      return false;
    }
    if (pass.isEmpty) {
      _showSnack("Ingresa tu contraseña");
      return false;
    }
    return true;
  }

  Future<void> _login() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.iniciarSesion(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      _showSnack(e.toString(), color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack("Ingresa tu correo institucional primero");
      return;
    }

    try {
      await _authService.recuperarContrasena(email);
      _showSnack("Enlace de recuperación enviado a tu correo", color: Colors.green);
    } catch (e) {
      _showSnack(e.toString(), color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1565C0),
                  Color(0xFF1E88E5),
                  Color(0xFFE3F2FD),
                ],
              ),
            ),
          ),

          // Burbujas decorativas
          Positioned(
            top: -90,
            right: -80,
            child: _Blob(size: 240, opacity: 0.18),
          ),
          Positioned(
            bottom: -110,
            left: -70,
            child: _Blob(size: 260, opacity: 0.14),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Card(
                        elevation: 14,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0).withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.school, size: 38, color: Color(0xFF1565C0)),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "UniEscom",
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Inicia sesión con tu correo institucional",
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),

                              // Inputs
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: "Correo institucional",
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  labelText: "Contraseña",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Botón
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1565C0),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: _isLoading
                                        ? const SizedBox(
                                            key: ValueKey("loader"),
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text(
                                            "INGRESAR",
                                            key: ValueKey("text"),
                                            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                            );
                                          },
                                    child: const Text("Regístrate"),
                                  ),
                                  const Text("•", style: TextStyle(color: Colors.black38)),
                                  TextButton(
                                    onPressed: _isLoading ? null : _forgotPassword,
                                    child: const Text("Olvidé mi contraseña"),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double opacity;
  const _Blob({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}
