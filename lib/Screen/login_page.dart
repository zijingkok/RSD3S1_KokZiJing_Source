import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;
  bool _loading = false;

  // Palette
  static const _bg = Color(0xFFF5F7FA);
  static const _ink = Color(0xFF1D2A32);
  static const _muted = Color(0xFF6A7A88);
  static const _stroke = Color(0xFFE6ECF1);
  static const _primary = Color(0xFF1E88E5);
  static const _primaryDark = Color(0xFF1565C0);

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  // TEMP while designing UI
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DashboardScreen()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _stroke),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _stroke),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primary, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  // Big centered logo slightly toward the top
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  Image.asset(
                    'assets/images/GodlikeLogo.png',
                    height: 250,           // try 180–200 if you want even bigger
                    width: width * 0.82,   // wider, still responsive
                    fit: BoxFit.contain,
                  ),

                  const Text(
                    'Manager Login',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Access your workshop dashboard',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Card with form
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _stroke),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Email',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailC,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec('manager@company.com'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter email';
                              }
                              final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(v.trim());
                              if (!ok) return 'Invalid email format';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Password',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordC,
                            obscureText: _obscure,
                            decoration: _dec('••••••••').copyWith(
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: _muted,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please enter password';
                              }
                              if (v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? true),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Remember Me',
                                style: TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .2,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: _PrimaryButton(
                              label: _loading ? 'Signing in…' : 'Sign In',
                              onPressed: _loading ? null : _signIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- Primary gradient button ---------- */
class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const _PrimaryButton({required this.onPressed, required this.label});

  static const _primary = _LoginPageState._primary;
  static const _primaryDark = _LoginPageState._primaryDark;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: enabled ? 1 : .6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [_primary, _primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
