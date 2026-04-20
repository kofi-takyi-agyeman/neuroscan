import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../models/models.dart';

// ── Mono label chip ───────────────────────────────────────────
class ChipLabel extends StatelessWidget {
  final String text;
  final Color color;
  const ChipLabel(this.text, {super.key, this.color = C.teal});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(text,
      style: GoogleFonts.spaceMono(
        color: color, fontSize: 9, letterSpacing: 1.2,
      ),
    ),
  );
}

// ── Section header ────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(
          color: C.t1, fontSize: 15, fontWeight: FontWeight.w700,
        )),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: GoogleFonts.plusJakartaSans(
              color: C.teal, fontSize: 13, fontWeight: FontWeight.w500,
            )),
          ),
      ],
    ),
  );
}

// ── Brain painter (reusable) ──────────────────────────────────
class BrainPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double strokeWidth;
  BrainPainter({this.color = C.teal, this.opacity = 1.0, this.strokeWidth = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.36;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withOpacity(opacity)
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(cx, cy - r * .7)
      ..cubicTo(cx - r*.8, cy - r*.9, cx - r*1.0, cy - r*.2, cx - r*.85, cy + r*.3)
      ..cubicTo(cx - r*.7, cy + r*.7, cx - r*.2, cy + r*.65, cx, cy + r*.2)
      ..moveTo(cx, cy - r*.7)
      ..cubicTo(cx + r*.8, cy - r*.9, cx + r*1.0, cy - r*.2, cx + r*.85, cy + r*.3)
      ..cubicTo(cx + r*.7, cy + r*.7, cx + r*.2, cy + r*.65, cx, cy + r*.2)
      ..moveTo(cx, cy - r*.7)
      ..lineTo(cx, cy + r*.2);
    for (int i = 0; i < 4; i++) {
      final fy = cy - r*.35 + i * r*.22;
      path
        ..moveTo(cx - r*.52, fy)
        ..cubicTo(cx - r*.32, fy - r*.08, cx - r*.12, fy + r*.08, cx - r*.02, fy)
        ..moveTo(cx + r*.52, fy)
        ..cubicTo(cx + r*.32, fy - r*.08, cx + r*.12, fy + r*.08, cx + r*.02, fy);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(BrainPainter o) =>
      o.color != color || o.opacity != opacity || o.strokeWidth != strokeWidth;
}

// ── Scan card ─────────────────────────────────────────────────
class ScanCard extends StatelessWidget {
  final ScanRecord scan;
  final VoidCallback? onTap;
  const ScanCard(this.scan, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cls = scan.result;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: C.cardGrad,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.divider),
        ),
        child: Row(children: [
          // MRI thumb
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: C.bg, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cls.color.withOpacity(0.35)),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(28, 28),
                painter: BrainPainter(color: cls.color, strokeWidth: 1.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(scan.patientName, style: GoogleFonts.plusJakartaSans(
                    color: C.t1, fontSize: 13, fontWeight: FontWeight.w600,
                  )),
                  ChipLabel(
                    cls.isPositive ? cls.label.toUpperCase() : 'CLEAR',
                    color: cls.color,
                  ),
                ]),
              const SizedBox(height: 3),
              Text('${scan.scanId}  •  ${scan.timestamp}',
                style: GoogleFonts.spaceMono(color: C.t3, fontSize: 10)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: scan.confidence,
                      backgroundColor: C.divider,
                      valueColor: AlwaysStoppedAnimation(cls.color),
                      minHeight: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(scan.confidence * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.spaceMono(color: cls.color, fontSize: 10)),
              ]),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Patient avatar tile ───────────────────────────────────────
class PatientTile extends StatelessWidget {
  final Patient patient;
  final VoidCallback? onTap;
  const PatientTile(this.patient, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final latest = patient.scans.isNotEmpty ? patient.scans.first : null;
    final cls = latest?.result;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: C.cardGrad,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.divider),
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (cls?.color ?? C.teal).withOpacity(0.3),
                  (cls?.color ?? C.teal).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                patient.name.split(' ').map((e) => e[0]).take(2).join(),
                style: GoogleFonts.plusJakartaSans(
                  color: cls?.color ?? C.teal,
                  fontSize: 14, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(patient.name, style: GoogleFonts.plusJakartaSans(
                  color: C.t1, fontSize: 13, fontWeight: FontWeight.w600,
                )),
                if (cls != null)
                  ChipLabel(cls.label.toUpperCase(), color: cls.color),
              ]),
              const SizedBox(height: 3),
              Text(
                '${patient.id}  •  ${patient.age}y  •  ${patient.gender}',
                style: GoogleFonts.spaceMono(color: C.t3, fontSize: 10),
              ),
              if (latest != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Last scan: ${latest.timestamp}',
                  style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 11),
                ),
              ],
            ],
          )),
          const Icon(Icons.chevron_right, color: C.t3, size: 18),
        ]),
      ),
    );
  }
}

// ── Circular confidence gauge ─────────────────────────────────
class ConfidenceGauge extends StatelessWidget {
  final double value;
  final Color color;
  final double size;
  const ConfidenceGauge({super.key, required this.value, required this.color, this.size = 100});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: CustomPaint(
      painter: _GaugePainter(value: value, color: color),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('${(value * 100).toStringAsFixed(1)}%',
          style: GoogleFonts.spaceMono(
            color: color, fontSize: size * 0.17, fontWeight: FontWeight.w700,
          )),
        Text('conf.', style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: size * 0.1)),
      ])),
    ),
  );
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  const _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width / 2 - 8;
    canvas.drawCircle(Offset(cx, cy), r,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 7..color = C.divider);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2, 2 * math.pi * value, false,
      Paint()
        ..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter o) => o.value != value || o.color != color;
}

// ── Primary teal button ───────────────────────────────────────
class TealButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;
  final double height;
  const TealButton({
    super.key, required this.label, this.icon, this.onTap,
    this.loading = false, this.height = 54,
  });

  @override
  State<TealButton> createState() => _TealButtonState();
}

class _TealButtonState extends State<TealButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 110), lowerBound: 0, upperBound: 0.04,
  );

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
    onTapCancel: () => _ctrl.reverse(),
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: 1 - _ctrl.value,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: C.tealGrad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: C.teal.withOpacity(0.28),
              blurRadius: 18, offset: const Offset(0, 7),
            )],
          ),
          child: Center(child: widget.loading
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(
                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(C.bg)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: C.bg, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(widget.label, style: GoogleFonts.plusJakartaSans(
                  color: C.bg, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: .5,
                )),
              ]),
          ),
        ),
      ),
    ),
  );
}

// ── Stat card ─────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;
  const StatCard({
    super.key, required this.label, required this.value,
    required this.delta, required this.icon, this.color = C.teal,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: C.cardGrad, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: C.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
      const SizedBox(height: 10),
      Text(value, style: GoogleFonts.plusJakartaSans(
        color: C.t1, fontSize: 20, fontWeight: FontWeight.w800,
      )),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 10)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: C.ok.withOpacity(0.1), borderRadius: BorderRadius.circular(4),
        ),
        child: Text(delta, style: GoogleFonts.spaceMono(
          color: C.ok, fontSize: 9, letterSpacing: .5,
        )),
      ),
    ]),
  );
}
