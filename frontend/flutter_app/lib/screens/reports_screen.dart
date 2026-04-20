import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../services/app_store.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    AppStore().addListener(_onUpdate);
  }

  @override
  void dispose() {
    AppStore().removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  String _buildReportText(AppStore store) {
    final now = DateFormat('d MMMM yyyy, h:mm a').format(DateTime.now());
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║        NEUROSCAN AI — REPORT         ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln('Generated: $now');
    buf.writeln('');
    buf.writeln('SUMMARY');
    buf.writeln('───────────────────────────────────────');
    buf.writeln('Total Scans    : ${store.totalScans}');
    buf.writeln('Positive       : ${store.positiveScans}');
    buf.writeln('Patients       : ${store.patients.length}');
    buf.writeln('');
    buf.writeln('SCAN HISTORY');
    buf.writeln('───────────────────────────────────────');
    for (final s in store.recentScans) {
      buf.writeln('${s.scanId}  |  ${s.patientName}  |  ${s.result.label}  |  ${(s.confidence*100).toStringAsFixed(1)}%  |  ${s.fullTimestamp}');
    }
    buf.writeln('');
    buf.writeln('NeuroScan AI  •  HIPAA Compliant  •  AES-256');
    return buf.toString();
  }

  void _exportReport(BuildContext context) {
    final store = AppStore();
    if (store.totalScans == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No scans to export yet'),
        backgroundColor: C.warn, behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final text = _buildReportText(store);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.description_outlined, color: C.teal, size: 22),
                const SizedBox(width: 10),
                Text('Export Report', style: GoogleFonts.plusJakartaSans(
                    color: C.t1, fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: C.t3, size: 20)),
              ]),
              const SizedBox(height: 14),
              Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: C.divider)),
                child: SingleChildScrollView(
                  child: Text(text, style: GoogleFonts.spaceMono(
                      color: C.t2, fontSize: 9, height: 1.6)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Report copied to clipboard'),
                      backgroundColor: C.ok, behavior: SnackBarBehavior.floating,
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: C.divider)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.content_copy_outlined, color: C.teal, size: 16),
                      const SizedBox(width: 6),
                      Text('Copy', style: GoogleFonts.plusJakartaSans(
                          color: C.teal, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: TealButton(
                  label: 'Share',
                  icon: Icons.share_outlined,
                  height: 44,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Opening share sheet...'),
                      backgroundColor: C.ok, behavior: SnackBarBehavior.floating,
                    ));
                  },
                )),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore();
    final scans = store.recentScans;
    final breakdown = store.classBreakdown;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(children: [
        Container(
          color: C.bg,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 14,
            left: 20, right: 20, bottom: 14,
          ),
          child: Row(children: [
            Text('Reports', style: GoogleFonts.plusJakartaSans(
                color: C.t1, fontSize: 22, fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.divider)),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, color: C.teal, size: 14),
                const SizedBox(width: 6),
                Text(DateFormat('MMM yyyy').format(now),
                    style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 12)),
              ]),
            ),
          ]),
        ),

        Expanded(child: scans.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.bar_chart_outlined, color: C.t3, size: 48),
              const SizedBox(height: 12),
              Text('No reports yet', style: GoogleFonts.plusJakartaSans(
                  color: C.t1, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Complete a scan to see reports here',
                  style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 13)),
            ]))
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              physics: const BouncingScrollPhysics(),
              children: [

                // Summary cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Expanded(child: _BigStat(label: 'Total Scans', value: '${store.totalScans}',
                        sub: 'This session', color: C.teal)),
                    const SizedBox(width: 10),
                    Expanded(child: _BigStat(label: 'Positive', value: '${store.positiveScans}',
                        sub: '${store.totalScans > 0 ? (store.positiveScans / store.totalScans * 100).toStringAsFixed(1) : 0}% rate',
                        color: C.err)),
                    const SizedBox(width: 10),
                    Expanded(child: _BigStat(label: 'Patients', value: '${store.patients.length}',
                        sub: 'registered', color: C.ok)),
                  ]),
                ),

                const SizedBox(height: 22),

                // Accuracy by class
                _AccuracyByClass(),
                const SizedBox(height: 22),

                // Bar chart
                if (breakdown.values.any((v) => v > 0)) ...[
                  _ClassBarChart(breakdown: breakdown),
                  const SizedBox(height: 22),
                ],

                // All scans header + export
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('All Scans (${scans.length})', style: GoogleFonts.plusJakartaSans(
                        color: C.t1, fontSize: 15, fontWeight: FontWeight.w700)),
                    GestureDetector(
                      onTap: () => _exportReport(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: C.tealGlow, borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: C.tealBorder)),
                        child: Row(children: [
                          const Icon(Icons.download_outlined, color: C.teal, size: 14),
                          const SizedBox(width: 5),
                          Text('Export', style: GoogleFonts.plusJakartaSans(
                              color: C.teal, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                ...scans.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ScanCard(s),
                )),
              ],
            ),
        ),
      ]),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label, value, sub; final Color color;
  const _BigStat({required this.label, required this.value, required this.sub, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(gradient: C.cardGrad, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.divider)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 10)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.plusJakartaSans(
          color: color, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 3),
      Text(sub, style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 9, height: 1.4)),
    ]),
  );
}

class _AccuracyByClass extends StatelessWidget {
  static const data = [
    (cls: TumorClass.glioma,     acc: 0.971, f1: 0.968),
    (cls: TumorClass.meningioma, acc: 0.963, f1: 0.959),
    (cls: TumorClass.pituitary,  acc: 0.981, f1: 0.978),
    (cls: TumorClass.noTumor,    acc: 0.986, f1: 0.984),
  ];
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: C.cardGrad, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Model Accuracy by Class', style: GoogleFonts.plusJakartaSans(
              color: C.t1, fontSize: 14, fontWeight: FontWeight.w600)),
          const ChipLabel('4-CLASS MODEL', color: C.info),
        ]),
        const SizedBox(height: 16),
        Table(columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.5)},
          children: [
            TableRow(children: [_th('CLASS'), _th('ACCURACY'), _th('F1-SCORE')]),
            ...data.map((d) => TableRow(children: [
              _td(d.cls.label, d.cls.color),
              _tdBar(d.acc, d.cls.color),
              _tdVal('${(d.f1 * 100).toStringAsFixed(1)}%', d.cls.color),
            ])),
          ]),
      ]),
    ),
  );

  Widget _th(String t) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9, letterSpacing: 1)));
  Widget _td(String t, Color c) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      Text(t, style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 12)),
    ]));
  Widget _tdBar(double v, Color c) => Padding(padding: const EdgeInsets.only(bottom: 10, right: 10),
    child: Row(children: [
      Expanded(child: Stack(children: [
        Container(height: 5, decoration: BoxDecoration(color: C.divider, borderRadius: BorderRadius.circular(3))),
        FractionallySizedBox(widthFactor: v, child: Container(height: 5,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)))),
      ])),
      const SizedBox(width: 6),
      Text('${(v * 100).toStringAsFixed(1)}%', style: GoogleFonts.spaceMono(color: c, fontSize: 10)),
    ]));
  Widget _tdVal(String t, Color c) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: GoogleFonts.spaceMono(color: c, fontSize: 11, fontWeight: FontWeight.w700)));
}

class _ClassBarChart extends StatelessWidget {
  final Map<TumorClass, int> breakdown;
  const _ClassBarChart({required this.breakdown});
  @override
  Widget build(BuildContext context) {
    final maxY = breakdown.values.fold(0, (a, b) => a > b ? a : b).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: C.cardGrad, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: C.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Diagnosis Distribution', style: GoogleFonts.plusJakartaSans(
              color: C.t1, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          SizedBox(height: 160,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY < 1 ? 5 : maxY + 1,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  getTitlesWidget: (val, _) {
                    final cls = TumorClass.values[val.toInt()];
                    return Padding(padding: const EdgeInsets.only(top: 6),
                      child: Text(cls.label.split(' ').first,
                          style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9)));
                  },
                )),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: C.divider, strokeWidth: .5)),
              borderData: FlBorderData(show: false),
              barGroups: breakdown.entries.toList().asMap().entries.map((e) =>
                BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: e.value.value.toDouble(),
                    color: e.value.key.color, width: 28,
                    borderRadius: BorderRadius.circular(6),
                    backDrawRodData: BackgroundBarChartRodData(
                        show: true, toY: maxY < 1 ? 5 : maxY + 1,
                        color: C.divider.withOpacity(0.3)),
                  ),
                ])).toList(),
            ))),
        ]),
      ),
    );
  }
}
