import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../services/app_store.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))..forward();

  @override
  void initState() {
    super.initState();
    AppStore().addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    AppStore().removeListener(_onStoreUpdate);
    _entry.dispose();
    super.dispose();
  }

  void _onStoreUpdate() => setState(() {});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore();
    final user = AuthService().currentUser;
    final name = user?['name'] ?? 'Doctor';
    final initials = name.split(' ').map((e) => e[0]).take(2).join();

    return FadeTransition(
      opacity: CurvedAnimation(parent: _entry, curve: Curves.easeOut),
      child: Column(children: [
        // Top bar
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 14,
            left: 20, right: 20, bottom: 14,
          ),
          color: C.bg,
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greeting(), style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 12)),
              const SizedBox(height: 2),
              Text(name, style: GoogleFonts.plusJakartaSans(
                  color: C.t1, fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
            const Spacer(),
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(gradient: C.tealGrad, borderRadius: BorderRadius.circular(11)),
              child: Center(child: Text(initials, style: GoogleFonts.plusJakartaSans(
                  color: C.bg, fontSize: 13, fontWeight: FontWeight.w700))),
            ),
          ]),
        ),

        Expanded(child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 4),

            // Live stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: StatCard(
                  label: 'Total Scans', value: '${store.totalScans}',
                  delta: store.totalScans == 0 ? 'No scans yet' : '+${store.totalScans} session',
                  icon: Icons.biotech_outlined, color: C.teal,
                )),
                const SizedBox(width: 10),
                Expanded(child: StatCard(
                  label: 'Positive', value: '${store.positiveScans}',
                  delta: store.totalScans == 0 ? '—' :
                      '${(store.positiveScans / store.totalScans * 100).toStringAsFixed(0)}% rate',
                  icon: Icons.warning_amber_rounded, color: C.err,
                )),
                const SizedBox(width: 10),
                Expanded(child: StatCard(
                  label: 'Patients', value: '${store.patients.length}',
                  delta: 'registered',
                  icon: Icons.people_outline, color: C.ok,
                )),
              ]),
            ),

            const SizedBox(height: 22),

            // Class breakdown — only show if there are scans
            if (store.totalScans > 0) ...[
              _ClassPieRow(breakdown: store.classBreakdown),
              const SizedBox(height: 22),
            ],

            // Weekly activity
            _WeeklyChart(total: store.weeklyTotal, positive: store.weeklyPositive),
            const SizedBox(height: 22),

            // Recent scans
            SectionHeader('Recent Scans', action: store.recentScans.isNotEmpty ? 'See all' : null),
            const SizedBox(height: 10),
            if (store.recentScans.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.divider)),
                  child: Column(children: [
                    const Icon(Icons.document_scanner_outlined, color: C.t3, size: 32),
                    const SizedBox(height: 8),
                    Text('No scans yet', style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Go to Scan tab to analyse an MRI',
                        style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 12)),
                  ]),
                ),
              )
            else
              ...store.recentScans.take(3).map((s) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ScanCard(s),
              )),

            const SizedBox(height: 22),

            // Recent patients
            SectionHeader('Recent Patients', action: 'See all'),
            const SizedBox(height: 10),
            ...store.patients.take(3).map((p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PatientTile(p),
            )),
          ],
        )),
      ]),
    );
  }
}

class _ClassPieRow extends StatelessWidget {
  final Map<TumorClass, int> breakdown;
  const _ClassPieRow({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: C.cardGrad, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: C.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Tumor Class Breakdown', style: GoogleFonts.plusJakartaSans(
                color: C.t1, fontSize: 14, fontWeight: FontWeight.w600)),
            ChipLabel('$total total', color: C.teal),
          ]),
          const SizedBox(height: 16),
          SizedBox(height: 130, child: Row(children: [
            SizedBox(width: 130, height: 130,
              child: PieChart(PieChartData(
                sectionsSpace: 2, centerSpaceRadius: 32,
                sections: breakdown.entries.where((e) => e.value > 0).map((e) =>
                  PieChartSectionData(color: e.key.color, value: e.value.toDouble(),
                      radius: 36, showTitle: false)).toList(),
              ))),
            const SizedBox(width: 20),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: breakdown.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(color: e.key.color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.key.label,
                      style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 12))),
                  Text('${e.value}', style: GoogleFonts.spaceMono(
                      color: e.key.color, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Text('(${total > 0 ? (e.value / total * 100).toStringAsFixed(0) : 0}%)',
                      style: GoogleFonts.spaceMono(color: C.t3, fontSize: 10)),
                ]),
              )).toList(),
            )),
          ])),
        ]),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<int> total;
  final List<int> positive;
  const _WeeklyChart({required this.total, required this.positive});

  @override
  Widget build(BuildContext context) {
    final maxY = (total.isEmpty ? 5 : total.reduce((a, b) => a > b ? a : b)).toDouble();
    final chartMax = maxY < 1 ? 5.0 : maxY + 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: C.cardGrad, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: C.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Weekly Scan Activity', style: GoogleFonts.plusJakartaSans(
                color: C.t1, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('This week', style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9)),
          ]),
          const SizedBox(height: 18),
          SizedBox(height: 130,
            child: LineChart(LineChartData(
              minY: 0, maxY: chartMax,
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: chartMax / 4,
                getDrawingHorizontalLine: (_) => const FlLine(color: C.divider, strokeWidth: .5)),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (val, _) {
                    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                    final i = val.toInt();
                    if (i < 0 || i >= days.length) return const SizedBox();
                    final isToday = i == DateTime.now().weekday - 1;
                    return Text(days[i], style: GoogleFonts.spaceMono(
                        color: isToday ? C.teal : C.t3, fontSize: 9,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.normal));
                  },
                )),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                _line(total.asMap().entries.map((e) =>
                    FlSpot(e.key.toDouble(), e.value.toDouble())).toList(), C.teal),
                _line(positive.asMap().entries.map((e) =>
                    FlSpot(e.key.toDouble(), e.value.toDouble())).toList(), C.err),
              ],
            ))),
          const SizedBox(height: 12),
          Row(children: [
            _legend('Total scans', C.teal),
            const SizedBox(width: 18),
            _legend('Positive cases', C.err),
          ]),
        ]),
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots, isCurved: true, color: color, barWidth: 2.2,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: true, gradient: LinearGradient(
      colors: [color.withOpacity(0.15), color.withOpacity(0)],
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
    )),
  );

  Widget _legend(String label, Color color) => Row(children: [
    Container(width: 18, height: 2.5,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 6),
    Text(label, style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 11)),
  ]);
}
