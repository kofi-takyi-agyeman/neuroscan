import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  // Page 1
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _role = 'Doctor';

  // Page 2
  final _hospitalCtrl  = TextEditingController();
  String _specialty = '';
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass  = true;
  bool _obscureConf  = true;
  bool _agreeTerms   = false;

  bool _loading = false;
  String? _errorMsg;

  late final AnimationController _entry = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))..forward();

  // Role definitions with icon, description and permission list
  static const _roles = [
    _RoleInfo(
      name: 'Doctor',
      icon: Icons.medical_services_outlined,
      desc: 'Full clinical access',
      permissions: ['Order & view MRI scans', 'Manage patients', 'Export & share reports', 'Refer patients'],
    ),
    _RoleInfo(
      name: 'Radiologist',
      icon: Icons.biotech_outlined,
      desc: 'Scan reading & reporting',
      permissions: ['Read & analyse MRI scans', 'View all patients', 'Export reports'],
    ),
    _RoleInfo(
      name: 'Nurse',
      icon: Icons.health_and_safety_outlined,
      desc: 'Patient care support',
      permissions: ['View patient list', 'Register new patients', 'View scan results'],
    ),
    _RoleInfo(
      name: 'Admin',
      icon: Icons.admin_panel_settings_outlined,
      desc: 'System administration',
      permissions: ['Manage all records', 'Export reports', 'Register patients'],
    ),
    _RoleInfo(
      name: 'Patient',
      icon: Icons.person_outline,
      desc: 'Personal health record',
      permissions: ['View your own scans', 'View your reports'],
    ),
  ];

  final _specialties = [
    'Neurology', 'Radiology', 'Oncology', 'Neurosurgery',
    'General Medicine', 'Nursing', 'Pathology', 'Administration', 'Other',
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _hospitalCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    _entry.dispose();
    super.dispose();
  }

  bool _validatePage1() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Please enter your full name.'); return false;
    }
    if (!_emailCtrl.text.contains('@')) {
      setState(() => _errorMsg = 'Please enter a valid email address.'); return false;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Please enter your phone number.'); return false;
    }
    return true;
  }

  bool _validatePage2() {
    if (_hospitalCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Please enter your hospital or institution.'); return false;
    }
    if (_passCtrl.text.length < 8) {
      setState(() => _errorMsg = 'Password must be at least 8 characters.'); return false;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _errorMsg = 'Passwords do not match.'); return false;
    }
    if (!_agreeTerms) {
      setState(() => _errorMsg = 'Please agree to the terms and conditions.'); return false;
    }
    return true;
  }

  void _nextPage() {
    setState(() => _errorMsg = null);
    if (!_validatePage1()) return;
    setState(() => _page = 1);
    _pageCtrl.animateToPage(1,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  void _prevPage() {
    setState(() { _page = 0; _errorMsg = null; });
    _pageCtrl.animateToPage(0,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  Future<void> _submit() async {
    setState(() => _errorMsg = null);
    if (!_validatePage2()) return;
    setState(() => _loading = true);

    final result = await AuthService().signUp(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: _role,
      hospital: _hospitalCtrl.text.trim(),
      specialty: _specialty.isEmpty ? _role : _specialty,
      phone: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      setState(() => _errorMsg = result.error);
      return;
    }
    _showSuccess();
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64, height: 64,
              decoration: BoxDecoration(color: C.ok.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline, color: C.ok, size: 34)),
            const SizedBox(height: 18),
            Text('Account Created!', style: GoogleFonts.plusJakartaSans(
                color: C.t1, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Welcome, ${_nameCtrl.text.split(' ').first}.\nYou\'re signed in as $_role.\nYour credentials are saved.',
              style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TealButton(
              label: 'GET STARTED',
              icon: Icons.arrow_forward_rounded,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const MainShell(),
                    transitionDuration: const Duration(milliseconds: 600),
                    transitionsBuilder: (_, a, __, child) =>
                        FadeTransition(opacity: a, child: child),
                  ),
                  (_) => false,
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              GestureDetector(
                onTap: _page == 0 ? () => Navigator.pop(context) : _prevPage,
                child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: C.divider)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: C.t2, size: 16)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Create Account', style: GoogleFonts.plusJakartaSans(
                    color: C.t1, fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Step ${_page + 1} of 2 — ${_page == 0 ? "Role & Personal Info" : "Professional Details"}',
                    style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9, letterSpacing: .8)),
              ])),
              Row(children: List.generate(2, (i) => Container(
                width: i == _page ? 20 : 7, height: 7,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                    color: i == _page ? C.teal : C.divider,
                    borderRadius: BorderRadius.circular(4)),
              ))),
            ]),
          ),

          // Progress bar
          Container(
            height: 2, margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: C.divider, borderRadius: BorderRadius.circular(1)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_page + 1) / 2,
              child: Container(decoration: BoxDecoration(
                  gradient: C.tealGrad, borderRadius: BorderRadius.circular(1))),
            ),
          ),

          const SizedBox(height: 4),

          Expanded(child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [_buildPage1(), _buildPage2()],
          )),
        ]),
      ),
    );
  }

  // ── Page 1: Role & Personal Info ─────────────────────────
  Widget _buildPage1() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),
      RichText(text: TextSpan(children: [
        TextSpan(text: 'Select your\n', style: GoogleFonts.plusJakartaSans(
            color: C.t1, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
        TextSpan(text: 'role', style: GoogleFonts.plusJakartaSans(
            color: C.teal, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
      ])),
      const SizedBox(height: 6),
      Text('Your role determines what you can access.',
          style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 13)),
      const SizedBox(height: 16),

      // Role cards with permissions
      ..._roles.map((r) {
        final selected = _role == r.name;
        return GestureDetector(
          onTap: () => setState(() { _role = r.name; _errorMsg = null; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? C.teal.withOpacity(0.08) : C.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? C.teal : C.divider,
                  width: selected ? 1.5 : 1),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: selected ? C.teal.withOpacity(0.15) : C.surface,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(r.icon, color: selected ? C.teal : C.t3, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(r.name, style: GoogleFonts.plusJakartaSans(
                      color: selected ? C.teal : C.t1, fontSize: 14,
                      fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(r.desc, style: GoogleFonts.plusJakartaSans(
                      color: C.t3, fontSize: 11)),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4,
                  children: r.permissions.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: selected ? C.teal.withOpacity(0.1) : C.surface,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: selected ? C.tealBorder : C.divider)),
                    child: Text(p, style: GoogleFonts.plusJakartaSans(
                        color: selected ? C.teal : C.t3, fontSize: 10)),
                  )).toList(),
                ),
              ])),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: C.teal, size: 20),
            ]),
          ),
        );
      }),

      const SizedBox(height: 20),

      // Personal fields
      _Label('FULL NAME'),
      const SizedBox(height: 6),
      _Field(_nameCtrl, _role == 'Patient' ? 'Your full name' : 'Dr. Kofi Mensah',
          Icons.person_outline, onChange: () => setState(() => _errorMsg = null)),
      const SizedBox(height: 14),

      _Label('EMAIL ADDRESS'),
      const SizedBox(height: 6),
      _Field(_emailCtrl, 'you@hospital.org', Icons.email_outlined,
          keyboard: TextInputType.emailAddress,
          onChange: () => setState(() => _errorMsg = null)),
      const SizedBox(height: 14),

      _Label('PHONE NUMBER'),
      const SizedBox(height: 6),
      _Field(_phoneCtrl, '+233 24 000 0000', Icons.phone_outlined,
          keyboard: TextInputType.phone,
          onChange: () => setState(() => _errorMsg = null)),

      if (_errorMsg != null) ...[
        const SizedBox(height: 14),
        _ErrorBanner(_errorMsg!),
      ],

      const SizedBox(height: 24),
      TealButton(label: 'CONTINUE', icon: Icons.arrow_forward_rounded, onTap: _nextPage),
      const SizedBox(height: 16),
      Center(child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: RichText(text: TextSpan(children: [
          TextSpan(text: 'Already have an account? ',
              style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 13)),
          TextSpan(text: 'Sign in',
              style: GoogleFonts.plusJakartaSans(
                  color: C.teal, fontSize: 13, fontWeight: FontWeight.w600)),
        ])),
      )),
      const SizedBox(height: 30),
    ]),
  );

  // ── Page 2: Professional Details ─────────────────────────
  Widget _buildPage2() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),
      RichText(text: TextSpan(children: [
        TextSpan(text: 'Professional\n', style: GoogleFonts.plusJakartaSans(
            color: C.t1, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
        TextSpan(text: 'details', style: GoogleFonts.plusJakartaSans(
            color: C.teal, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
      ])),
      const SizedBox(height: 6),
      Text('Almost done — a few more details.',
          style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 13)),
      const SizedBox(height: 20),

      _Label(_role == 'Patient' ? 'HOSPITAL / CLINIC' : 'HOSPITAL / INSTITUTION'),
      const SizedBox(height: 6),
      _Field(_hospitalCtrl,
          _role == 'Patient' ? 'Your hospital or clinic' : 'Korle Bu Teaching Hospital',
          Icons.local_hospital_outlined,
          onChange: () => setState(() => _errorMsg = null)),
      const SizedBox(height: 14),

      _Label('SPECIALTY (OPTIONAL)'),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.divider)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _specialty.isEmpty ? null : _specialty,
            hint: Padding(padding: const EdgeInsets.only(left: 14),
              child: Text('Select specialty',
                  style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 14))),
            isExpanded: true, dropdownColor: C.card,
            icon: const Padding(padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: C.t3)),
            items: _specialties.map((s) => DropdownMenuItem(value: s,
              child: Padding(padding: const EdgeInsets.only(left: 14),
                child: Text(s, style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 14)))
            )).toList(),
            onChanged: (v) => setState(() { _specialty = v ?? ''; _errorMsg = null; }),
          ),
        ),
      ),
      const SizedBox(height: 14),

      _Label('CREATE PASSWORD'),
      const SizedBox(height: 6),
      TextField(
        controller: _passCtrl, obscureText: _obscurePass,
        style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 14),
        onChanged: (_) => setState(() => _errorMsg = null),
        decoration: InputDecoration(
          hintText: 'Min. 8 characters',
          prefixIcon: const Icon(Icons.lock_outline, color: C.teal, size: 19),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePass = !_obscurePass),
            child: Icon(_obscurePass
                ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: C.t3, size: 19)),
        ),
      ),

      if (_passCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 8),
        _PasswordStrength(password: _passCtrl.text),
      ],

      const SizedBox(height: 14),

      _Label('CONFIRM PASSWORD'),
      const SizedBox(height: 6),
      TextField(
        controller: _confirmCtrl, obscureText: _obscureConf,
        style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 14),
        onChanged: (_) => setState(() => _errorMsg = null),
        decoration: InputDecoration(
          hintText: 'Re-enter your password',
          prefixIcon: const Icon(Icons.lock_outline, color: C.teal, size: 19),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscureConf = !_obscureConf),
            child: Icon(_obscureConf
                ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: C.t3, size: 19)),
        ),
      ),
      const SizedBox(height: 18),

      // Terms
      GestureDetector(
        onTap: () => setState(() => _agreeTerms = !_agreeTerms),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20, height: 20, margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
                color: _agreeTerms ? C.teal : Colors.transparent,
                border: Border.all(color: _agreeTerms ? C.teal : C.t3, width: 1.5),
                borderRadius: BorderRadius.circular(5)),
            child: _agreeTerms
                ? const Icon(Icons.check, size: 13, color: C.bg) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: RichText(text: TextSpan(children: [
            TextSpan(text: 'I agree to the ',
                style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 13)),
            TextSpan(text: 'Terms of Service',
                style: GoogleFonts.plusJakartaSans(color: C.teal, fontSize: 13,
                    fontWeight: FontWeight.w500)),
            TextSpan(text: ' and ',
                style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 13)),
            TextSpan(text: 'Privacy Policy',
                style: GoogleFonts.plusJakartaSans(color: C.teal, fontSize: 13,
                    fontWeight: FontWeight.w500)),
            TextSpan(text: '. Patient data is handled per HIPAA.',
                style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 13)),
          ]))),
        ]),
      ),

      if (_errorMsg != null) ...[
        const SizedBox(height: 14),
        _ErrorBanner(_errorMsg!),
      ],

      const SizedBox(height: 24),
      TealButton(
        label: 'CREATE ACCOUNT',
        icon: Icons.person_add_outlined,
        onTap: _submit,
        loading: _loading,
      ),
      const SizedBox(height: 30),
    ]),
  );
}

// ── Role info data class ──────────────────────────────────────
class _RoleInfo {
  final String name;
  final IconData icon;
  final String desc;
  final List<String> permissions;
  const _RoleInfo({required this.name, required this.icon,
      required this.desc, required this.permissions});
}

// ── Helpers ───────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9, letterSpacing: 1.4));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
  final VoidCallback? onChange;
  const _Field(this.ctrl, this.hint, this.icon,
      {this.keyboard = TextInputType.text, this.onChange});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, keyboardType: keyboard,
    style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 14),
    onChanged: (_) => onChange?.call(),
    decoration: InputDecoration(hintText: hint,
        prefixIcon: Icon(icon, color: C.teal, size: 19)),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: C.errGlow, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.err.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: C.err, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: GoogleFonts.plusJakartaSans(color: C.err, fontSize: 12))),
    ]),
  );
}

class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  int get _strength {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength;
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    final colors = [C.err, C.warn, C.info, C.ok];
    return Row(children: [
      ...List.generate(4, (i) => Expanded(child: Container(
        height: 3, margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
            color: i < s ? colors[s - 1] : C.divider,
            borderRadius: BorderRadius.circular(2))))),
      const SizedBox(width: 8),
      Text(s > 0 ? labels[s - 1] : 'Too short',
          style: GoogleFonts.spaceMono(
              color: s > 0 ? colors[s - 1] : C.t3, fontSize: 9)),
    ]);
  }
}
