import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  late final AnimationController _scan = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  late final AnimationController _entry = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))..forward();
  late final AnimationController _bar = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800));

  late final Animation<double> _pulseAnim =
      Tween(begin: 0.88, end: 1.0).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  late final Animation<double> _scanAnim =
      Tween(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _scan, curve: Curves.easeInOut));
  late final Animation<double> _entryAnim =
      CurvedAnimation(parent: _entry, curve: Curves.easeOut);
  late final Animation<double> _barAnim =
      CurvedAnimation(parent: _bar, curve: Curves.easeInOut);

  int _loadStep = 0;
  static const _steps = [
    'Initializing neural engine...',
    'Loading CNN model weights...',
    'Calibrating 4-class classifier...',
    'System ready.',
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      _bar.forward();
      _stepLoop();
    });
    // Navigate after splash completes
    Future.delayed(const Duration(milliseconds: 3400), _navigate);
  }

  void _stepLoop() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _loadStep = i);
    }
  }

  void _navigate() async {
    if (!mounted) return;
    // Init loads users and restores session from shared_preferences
    await AuthService().init();
    if (!mounted) return;
    final destination = AuthService().isLoggedIn
        ? const MainShell()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => destination,
      transitionDuration: const Duration(milliseconds: 700),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    _pulse.dispose(); _scan.dispose(); _entry.dispose(); _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: C.bg,
      body: FadeTransition(
        opacity: _entryAnim,
        child: Stack(children: [
          // Grid background
          CustomPaint(size: size, painter: _GridPainter()),

          // Glow blob
          Positioned(
            top: size.height * 0.18, left: size.width / 2 - 140,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(width: 280, height: 280,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      C.teal.withOpacity(0.10), Colors.transparent]))),
              ),
            ),
          ),

          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Animated brain
            AnimatedBuilder(
              animation: Listenable.merge([_pulseAnim, _scanAnim]),
              builder: (_, __) => SizedBox(width: 190, height: 190,
                child: CustomPaint(painter: _SplashBrainPainter(
                    pulse: _pulseAnim.value, scan: _scanAnim.value))),
            ),

            const SizedBox(height: 36),

            // Wordmark
            AnimatedBuilder(
              animation: _entryAnim,
              builder: (_, __) => Opacity(
                opacity: _entryAnim.value,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - _entryAnim.value)),
                  child: Column(children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: 'Neuro', style: GoogleFonts.plusJakartaSans(
                          color: C.t1, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
                      TextSpan(text: 'Scan', style: GoogleFonts.plusJakartaSans(
                          color: C.teal, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
                    ])),
                    const SizedBox(height: 6),
                    Text('AI-POWERED MRI CLASSIFICATION SYSTEM',
                        style: GoogleFonts.spaceMono(color: C.t3, fontSize: 10, letterSpacing: 2)),
                  ]),
                ),
              ),
            ),

            const SizedBox(height: 56),

            // Progress bar + step text
            SizedBox(width: 220,
              child: AnimatedBuilder(
                animation: _barAnim,
                builder: (_, __) => Column(children: [
                  Stack(children: [
                    Container(height: 2, color: C.divider),
                    Container(height: 2, width: 220 * _barAnim.value,
                        decoration: const BoxDecoration(gradient: C.tealGrad)),
                  ]),
                  const SizedBox(height: 12),
                  Text(_steps[_loadStep], style: GoogleFonts.spaceMono(
                      color: C.teal.withOpacity(0.75), fontSize: 10, letterSpacing: 1)),
                ]),
              ),
            ),
          ])),

          // 4-class badges
          Positioned(
            bottom: 36, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _entryAnim,
              builder: (_, __) => Opacity(
                opacity: _entryAnim.value,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _badge('Glioma', C.glioma),
                  _badge('Meningioma', C.mening),
                  _badge('Pituitary', C.pitu),
                  _badge('No Tumor', C.noTumor),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.2))),
    child: Text(label, style: GoogleFonts.spaceMono(color: color, fontSize: 8, letterSpacing: .8)),
  );
}

// ── Brain painter ─────────────────────────────────────────────
class _SplashBrainPainter extends CustomPainter {
  final double pulse, scan;
  _SplashBrainPainter({required this.pulse, required this.scan});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.37 * pulse;

    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(Offset(cx, cy), r + i * 15,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 1
            ..color = C.teal.withOpacity(0.05 * i));
    }

    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5
          ..color = C.teal.withOpacity(0.4));

    final bp = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round..color = C.teal;
    final path = Path()
      ..moveTo(cx, cy - r * .7)
      ..cubicTo(cx - r*.8, cy - r*.9, cx - r*1.0, cy - r*.2, cx - r*.85, cy + r*.3)
      ..cubicTo(cx - r*.7, cy + r*.7, cx - r*.2, cy + r*.65, cx, cy + r*.2)
      ..moveTo(cx, cy - r*.7)
      ..cubicTo(cx + r*.8, cy - r*.9, cx + r*1.0, cy - r*.2, cx + r*.85, cy + r*.3)
      ..cubicTo(cx + r*.7, cy + r*.7, cx + r*.2, cy + r*.65, cx, cy + r*.2)
      ..moveTo(cx, cy - r*.7)..lineTo(cx, cy + r*.2);
    for (int i = 0; i < 4; i++) {
      final fy = cy - r*.35 + i * r*.22;
      path
        ..moveTo(cx - r*.52, fy)
        ..cubicTo(cx - r*.3, fy - r*.08, cx - r*.1, fy + r*.08, cx - r*.02, fy)
        ..moveTo(cx + r*.52, fy)
        ..cubicTo(cx + r*.3, fy - r*.08, cx + r*.1, fy + r*.08, cx + r*.02, fy);
    }
    canvas.drawPath(path, bp);

    final sy = cy + scan * r * 1.05;
    if (sy >= cy - r && sy <= cy + r) {
      final scanRect = Rect.fromLTWH(cx - r, sy - 1, r * 2, 2);
      canvas.drawLine(Offset(cx - r, sy), Offset(cx + r, sy),
          Paint()..shader = const LinearGradient(colors: [
            Colors.transparent, C.teal, C.cyan, C.teal, Colors.transparent,
          ]).createShader(scanRect)..strokeWidth = 2);
    }

    const bl = 14.0;
    final bx = cx - r * 1.18, by = cy - r * 1.18;
    final bp2 = Paint()..color = C.teal.withOpacity(0.5)
      ..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(bx, by + bl), Offset(bx, by), bp2);
    canvas.drawLine(Offset(bx, by), Offset(bx + bl, by), bp2);
    canvas.drawLine(Offset(cx + r*1.18 - bl, by), Offset(cx + r*1.18, by), bp2);
    canvas.drawLine(Offset(cx + r*1.18, by), Offset(cx + r*1.18, by + bl), bp2);
    canvas.drawLine(Offset(bx, cy + r*1.18 - bl), Offset(bx, cy + r*1.18), bp2);
    canvas.drawLine(Offset(bx, cy + r*1.18), Offset(bx + bl, cy + r*1.18), bp2);
    canvas.drawLine(Offset(cx + r*1.18 - bl, cy + r*1.18), Offset(cx + r*1.18, cy + r*1.18), bp2);
    canvas.drawLine(Offset(cx + r*1.18, cy + r*1.18), Offset(cx + r*1.18, cy + r*1.18 - bl), bp2);
  }

  @override
  bool shouldRepaint(_SplashBrainPainter o) => o.pulse != pulse || o.scan != scan;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = C.teal.withOpacity(0.03)..strokeWidth = .5;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override bool shouldRepaint(_GridPainter _) => false;
}
