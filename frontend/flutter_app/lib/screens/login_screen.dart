import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true, _loading = false, _remember = false;
  int _roleIndex = 0;
  String? _errorMsg;

  late final AnimationController _entry = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))..forward();

  List<Animation<double>> get _anims => List.generate(8, (i) =>
      CurvedAnimation(
        parent: _entry,
        curve: Interval(i * 0.09, (i * 0.09 + 0.45).clamp(0, 1), curve: Curves.easeOut),
      ));

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); _entry.dispose(); super.dispose();
  }

  Widget _fade(int i, Widget child) => AnimatedBuilder(
    animation: _anims[i],
    builder: (_, __) => Opacity(
      opacity: _anims[i].value,
      child: Transform.translate(
          offset: Offset(0, 24 * (1 - _anims[i].value)), child: child),
    ),
  );

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'Please enter your email and password.');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });

    final result = await AuthService().login(email, pass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      setState(() => _errorMsg = result.error);
      return;
    }

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const MainShell(),
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
        child: child,
      ),
    ));
  }

  void _goToSignup() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const SignupScreen(),
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
        child: child,
      ),
    ));
  }

  void _goToForgotPassword() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const ForgotPasswordScreen(),
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(children: [
        Positioned(top: -100, right: -100, child: Container(
          width: 300, height: 300,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [C.teal.withOpacity(0.07), Colors.transparent])),
        )),
        Positioned(bottom: -80, left: -80, child: Container(
          width: 240, height: 240,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [C.info.withOpacity(0.05), Colors.transparent])),
        )),

        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Portal tag
            _fade(0, Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: C.tealGlow, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.tealBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: C.teal)),
                const SizedBox(width: 7),
                Text('NEUROSCAN SECURE PORTAL', style: GoogleFonts.spaceMono(
                    color: C.teal, fontSize: 9, letterSpacing: 1.5)),
              ]),
            )),
            const SizedBox(height: 26),

            // Title
            _fade(1, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(text: TextSpan(children: [
                TextSpan(text: 'Sign in to\nyour ', style: GoogleFonts.plusJakartaSans(
                    color: C.t1, fontSize: 32, fontWeight: FontWeight.w800,
                    height: 1.15, letterSpacing: -1)),
                TextSpan(text: 'account', style: GoogleFonts.plusJakartaSans(
                    color: C.teal, fontSize: 32, fontWeight: FontWeight.w800,
                    height: 1.15, letterSpacing: -1)),
              ])),
              const SizedBox(height: 10),
              Text('Access patient records, MRI analysis\nand diagnostic reports.',
                  style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 14, height: 1.6)),
            ])),

            SizedBox(height: MediaQuery.of(context).size.height * 0.035),

            // Role toggle
            _fade(2, Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: C.card, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.divider),
              ),
              child: Row(children: List.generate(2, (i) {
                final labels = ['Doctor / Radiologist', 'Patient'];
                final icons  = [Icons.medical_services_outlined, Icons.person_outline];
                final active = _roleIndex == i;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _roleIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: active ? C.teal.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: active ? Border.all(color: C.tealBorder) : null,
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(icons[i], color: active ? C.teal : C.t3, size: 16),
                      const SizedBox(width: 6),
                      Text(labels[i], style: GoogleFonts.plusJakartaSans(
                          color: active ? C.teal : C.t3, fontSize: 12,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                    ]),
                  ),
                ));
              })),
            )),

            const SizedBox(height: 22),

            // Email
            _fade(3, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _FieldLabel(_roleIndex == 0 ? 'PHYSICIAN ID / EMAIL' : 'PATIENT ID / EMAIL'),
              const SizedBox(height: 7),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 14),
                onChanged: (_) => setState(() => _errorMsg = null),
                decoration: InputDecoration(
                  hintText: _roleIndex == 0 ? 'doctor@hospital.org' : 'patient@email.com',
                  prefixIcon: Icon(
                    _roleIndex == 0 ? Icons.badge_outlined : Icons.person_outline,
                    color: C.teal, size: 19),
                ),
              ),
            ])),

            const SizedBox(height: 16),

            // Password
            _fade(3, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _FieldLabel('PASSWORD'),
              const SizedBox(height: 7),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 14),
                onChanged: (_) => setState(() => _errorMsg = null),
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: '••••••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, color: C.teal, size: 19),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: C.t3, size: 19),
                  ),
                ),
              ),
            ])),

            const SizedBox(height: 14),

            // Remember + forgot
            _fade(4, Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GestureDetector(
                onTap: () => setState(() => _remember = !_remember),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: _remember ? C.teal : Colors.transparent,
                      border: Border.all(color: _remember ? C.teal : C.t3, width: 1.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: _remember ? const Icon(Icons.check, size: 13, color: C.bg) : null,
                  ),
                  const SizedBox(width: 8),
                  Text('Keep me signed in',
                      style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 13)),
                ]),
              ),
              GestureDetector(
                onTap: _goToForgotPassword,
                child: Text('Forgot password?', style: GoogleFonts.plusJakartaSans(
                    color: C.teal, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ])),

            // Error message
            if (_errorMsg != null) ...[
              const SizedBox(height: 14),
              _fade(4, Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.errGlow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.err.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: C.err, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMsg!, style: GoogleFonts.plusJakartaSans(
                      color: C.err, fontSize: 12))),
                ]),
              )),
            ],

            const SizedBox(height: 20),

            // Demo accounts quick-fill
            _fade(4, _DemoAccounts(
              onSelect: (email, pass) {
                setState(() {
                  _emailCtrl.text = email;
                  _passCtrl.text = pass;
                  _errorMsg = null;
                });
              },
            )),

            const SizedBox(height: 20),

            // Sign in button
            _fade(5, TealButton(
              label: 'SIGN IN',
              icon: Icons.login_rounded,
              onTap: _login,
              loading: _loading,
            )),

            const SizedBox(height: 20),

            // Divider
            _fade(5, Row(children: [
              const Expanded(child: Divider(color: C.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('or sign in with', style: GoogleFonts.plusJakartaSans(
                    color: C.t3, fontSize: 12)),
              ),
              const Expanded(child: Divider(color: C.divider)),
            ])),

            const SizedBox(height: 16),

            // Auth alternatives
            _fade(6, Row(children: [
              Expanded(child: _AltButton(icon: Icons.fingerprint, label: 'Biometric', onTap: _login)),
              const SizedBox(width: 12),
              Expanded(child: _AltButton(icon: Icons.qr_code_scanner, label: 'ID Scan', onTap: _login)),
              const SizedBox(width: 12),
              Expanded(child: _AltButton(icon: Icons.security, label: '2FA', onTap: _login)),
            ])),

            const SizedBox(height: 28),

            // Sign up link
            _fade(7, Center(child: GestureDetector(
              onTap: _goToSignup,
              child: RichText(text: TextSpan(children: [
                TextSpan(text: "Don't have an account? ",
                    style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 14)),
                TextSpan(text: 'Create one',
                    style: GoogleFonts.plusJakartaSans(
                        color: C.teal, fontSize: 14, fontWeight: FontWeight.w600)),
              ])),
            ))),

            const SizedBox(height: 20),

            _fade(7, Center(child: Text(
              'HIPAA Compliant  •  AES-256  •  ISO 27001',
              style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9, letterSpacing: 1),
            ))),
            const SizedBox(height: 24),
          ]),
        )),
      ]),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);
  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9, letterSpacing: 1.4));
}

class _AltButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AltButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
          color: C.card, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.divider)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: C.teal, size: 19),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 10)),
      ]),
    ),
  );
}

// ── Demo accounts quick-fill ──────────────────────────────────
class _DemoAccounts extends StatelessWidget {
  final void Function(String email, String password) onSelect;
  const _DemoAccounts({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final accounts = AuthService().demoAccounts;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Divider(color: C.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('demo accounts', style: GoogleFonts.spaceMono(
              color: C.t3, fontSize: 9, letterSpacing: 1)),
        ),
        const Expanded(child: Divider(color: C.divider)),
      ]),
      const SizedBox(height: 10),
      ...accounts.map((a) => GestureDetector(
        onTap: () => onSelect(a['email']!, a['password']!),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.divider),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: C.tealGlow, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(
                a['name']!.split(' ').map((e) => e[0]).take(2).join(),
                style: GoogleFonts.plusJakartaSans(
                    color: C.teal, fontSize: 12, fontWeight: FontWeight.w700),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['name']!, style: GoogleFonts.plusJakartaSans(
                  color: C.t1, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${a['email']}  •  ${a['role']}',
                  style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: C.tealGlow, borderRadius: BorderRadius.circular(6)),
              child: Text('tap to fill', style: GoogleFonts.spaceMono(
                  color: C.teal, fontSize: 8, letterSpacing: .5)),
            ),
          ]),
        ),
      )),
    ]);
  }
}
