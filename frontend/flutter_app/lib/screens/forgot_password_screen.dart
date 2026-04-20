import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _errorMsg;

  late final AnimationController _entry = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))..forward();

  @override
  void dispose() { _emailCtrl.dispose(); _entry.dispose(); super.dispose(); }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _errorMsg = 'Please enter a valid email address.');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    final result = await AuthService().sendResetLink(email);
    if (!mounted) return;
    setState(() { _loading = false; });
    if (!result.success) {
      setState(() => _errorMsg = result.error);
    } else {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(children: [
        Positioned(top: -80, right: -80, child: Container(
          width: 220, height: 220,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [C.info.withOpacity(0.06), Colors.transparent])),
        )),

        SafeArea(child: Column(children: [
          // Back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: C.card, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: C.divider)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: C.t2, size: 16),
                ),
              ),
            ]),
          ),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedBuilder(
              animation: _entry,
              builder: (_, __) => Opacity(
                opacity: _entry.value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - _entry.value)),
                  child: _sent ? _buildSuccess() : _buildForm(),
                ),
              ),
            ),
          )),
        ])),
      ]),
    );
  }

  Widget _buildForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 16),

    Container(
      width: 56, height: 56,
      decoration: BoxDecoration(color: C.tealGlow, borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.lock_reset_outlined, color: C.teal, size: 28),
    ),
    const SizedBox(height: 20),

    RichText(text: TextSpan(children: [
      TextSpan(text: 'Reset your\n', style: GoogleFonts.plusJakartaSans(
          color: C.t1, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.8)),
      TextSpan(text: 'password', style: GoogleFonts.plusJakartaSans(
          color: C.teal, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.8)),
    ])),
    const SizedBox(height: 10),
    Text('Enter the email linked to your account and we\'ll send you a reset link.',
        style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 14, height: 1.6)),

    const SizedBox(height: 32),

    Text('EMAIL ADDRESS',
        style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9, letterSpacing: 1.4)),
    const SizedBox(height: 7),
    TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 14),
      onChanged: (_) => setState(() => _errorMsg = null),
      onSubmitted: (_) => _send(),
      decoration: const InputDecoration(
        hintText: 'your@email.com',
        prefixIcon: Icon(Icons.email_outlined, color: C.teal, size: 19),
      ),
    ),

    if (_errorMsg != null) ...[
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.errGlow, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.err.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: C.err, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(_errorMsg!, style: GoogleFonts.plusJakartaSans(
              color: C.err, fontSize: 12))),
        ]),
      ),
    ],

    const SizedBox(height: 28),

    TealButton(
      label: 'SEND RESET LINK',
      icon: Icons.send_outlined,
      onTap: _send,
      loading: _loading,
    ),

    const SizedBox(height: 20),

    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.divider),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: C.info, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'If you don\'t receive an email within 5 minutes, check your spam folder or contact your hospital IT administrator.',
          style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 12, height: 1.5),
        )),
      ]),
    ),
  ]);

  Widget _buildSuccess() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 40),
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: C.ok.withOpacity(0.12), shape: BoxShape.circle),
        child: const Icon(Icons.mark_email_read_outlined, color: C.ok, size: 38),
      ),
      const SizedBox(height: 24),
      Text('Check your inbox', style: GoogleFonts.plusJakartaSans(
          color: C.t1, fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text(
        'We sent a password reset link to\n${_emailCtrl.text}',
        style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 14, height: 1.6),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      TealButton(
        label: 'BACK TO SIGN IN',
        icon: Icons.login_rounded,
        onTap: () => Navigator.pop(context),
      ),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () => setState(() { _sent = false; _emailCtrl.clear(); }),
        child: Text('Try a different email',
            style: GoogleFonts.plusJakartaSans(
                color: C.teal, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    ],
  );
}
