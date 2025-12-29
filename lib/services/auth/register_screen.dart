import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nombreController = TextEditingController();
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
    _nombreController.dispose();
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
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (nombre.isEmpty || email.isEmpty || pass.isEmpty) {
      _showSnack("Por favor, llena todos los campos.");
      return false;
    }

    if (!email.contains("@") || !email.contains(".")) {
      _showSnack("Ingresa un correo válido.");
      return false;
    }

    // ✅ OPCIONAL: fuerza dominio institucional.
    // Si tu escuela usa @alumno.ipn.mx, déjalo así.
    // Si también aceptan otro (ej. @ipn.mx), agrega OR.
    final emailLower = email.toLowerCase();
    if (!emailLower.endsWith("@alumno.ipn.mx")) {
      _showSnack("Usa tu correo institucional @alumno.ipn.mx");
      return false;
    }

    if (pass.length < 6) {
      _showSnack("La contraseña debe tener al menos 6 caracteres.");
      return false;
    }

    return true;
  }

  Future<void> _registrar() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.registrarEstudiante(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nombre: _nombreController.text.trim(),
      );

      if (!mounted) return;

      _showSnack("Cuenta creada con éxito. Inicia sesión.", color: Colors.green);
      Navigator.pop(context); // Regresa al Login
    } catch (e) {
      _showSnack(e.toString(), color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Cuenta"),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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

          // Decoración
          const Positioned(top: -90, right: -80, child: _Blob(size: 240, opacity: 0.18)),
          const Positioned(bottom: -110, left: -70, child: _Blob(size: 260, opacity: 0.14)),

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
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0).withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.person_add_alt_1, size: 34, color: Color(0xFF1565C0)),
                              ),
                              const SizedBox(height: 12),

                              const Text(
                                "Únete a UniEscom",
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Usa tu correo institucional @alumno.ipn.mx",
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),

                              TextField(
                                controller: _nombreController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: "Nombre completo",
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                              const SizedBox(height: 12),

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
                                onSubmitted: (_) => _registrar(),
                                decoration: InputDecoration(
                                  labelText: "Contraseña",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  helperText: "Mínimo 6 caracteres",
                                ),
                              ),

                              const SizedBox(height: 18),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1565C0),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: _isLoading ? null : _registrar,
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
                                            "REGISTRARSE",
                                            key: ValueKey("text"),
                                            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: _isLoading ? null : () => Navigator.pop(context),
                                child: const Text("Ya tengo cuenta • Volver a iniciar sesión"),
                              ),
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
