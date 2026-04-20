import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../services/app_store.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});
  @override State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String _query = '';
  TumorClass? _filterClass;

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

  List<Patient> get _filtered {
    var list = AppStore().patients.toList();
    if (_query.isNotEmpty) {
      list = list.where((p) =>
        p.name.toLowerCase().contains(_query.toLowerCase()) ||
        p.id.toLowerCase().contains(_query.toLowerCase()) ||
        p.phone.contains(_query)).toList();
    }
    if (_filterClass != null) {
      list = list.where((p) =>
        p.scans.isNotEmpty && p.scans.first.result == _filterClass).toList();
    }
    return list;
  }

  void _showAddPatient() {
    final nameCtrl  = TextEditingController();
    final phoneCtrl = TextEditingController();
    final dobCtrl   = TextEditingController();
    int age = 30;
    String gender = 'Male';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 16,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: C.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add New Patient', style: GoogleFonts.plusJakartaSans(
                color: C.t1, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            _label('FULL NAME'),
            const SizedBox(height: 6),
            _field(nameCtrl, 'e.g. Kofi Mensah', Icons.person_outline),
            const SizedBox(height: 14),

            _label('PHONE NUMBER'),
            const SizedBox(height: 6),
            _field(phoneCtrl, '+233 24 000 0000', Icons.phone_outlined,
                keyboard: TextInputType.phone),
            const SizedBox(height: 14),

            _label('DATE OF BIRTH'),
            const SizedBox(height: 6),
            _field(dobCtrl, 'e.g. 15 Jan 1985', Icons.cake_outlined),
            const SizedBox(height: 14),

            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('AGE'),
                const SizedBox(height: 6),
                Row(children: [
                  GestureDetector(
                    onTap: () => setSheet(() { if (age > 1) age--; }),
                    child: _stepper(Icons.remove)),
                  Expanded(child: Center(child: Text('$age',
                      style: GoogleFonts.plusJakartaSans(
                          color: C.t1, fontSize: 18, fontWeight: FontWeight.w700)))),
                  GestureDetector(
                    onTap: () => setSheet(() => age++),
                    child: _stepper(Icons.add)),
                ]),
              ])),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('GENDER'),
                const SizedBox(height: 6),
                Row(children: ['M', 'F', 'O'].map((g) {
                  final full = g == 'M' ? 'Male' : g == 'F' ? 'Female' : 'Other';
                  return Expanded(child: GestureDetector(
                    onTap: () => setSheet(() => gender = full),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: gender == full ? C.tealGlow : C.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: gender == full ? C.tealBorder : C.divider),
                      ),
                      child: Center(child: Text(g, style: GoogleFonts.plusJakartaSans(
                          color: gender == full ? C.teal : C.t2, fontSize: 13,
                          fontWeight: gender == full ? FontWeight.w700 : FontWeight.normal))),
                    ),
                  ));
                }).toList()),
              ])),
            ]),

            const SizedBox(height: 24),
            TealButton(
              label: 'ADD PATIENT',
              icon: Icons.person_add_outlined,
              onTap: () {
                if (nameCtrl.text.trim().isEmpty) return;
                AppStore().addPatient(
                  name: nameCtrl.text.trim(),
                  age: age,
                  gender: gender,
                  phone: phoneCtrl.text.trim().isEmpty ? 'N/A' : phoneCtrl.text.trim(),
                  dob: dobCtrl.text.trim().isEmpty ? 'N/A' : dobCtrl.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${nameCtrl.text.trim()} added successfully'),
                  backgroundColor: C.ok, behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            const SizedBox(height: 28),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9, letterSpacing: 1.2));

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType keyboard = TextInputType.text}) =>
    TextField(controller: ctrl, keyboardType: keyboard,
      style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 14),
      decoration: InputDecoration(hintText: hint,
          prefixIcon: Icon(icon, color: C.teal, size: 18)));

  Widget _stepper(IconData icon) => Container(width: 34, height: 34,
    decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.divider)),
    child: Icon(icon, color: C.teal, size: 17));

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: C.bg,
      body: Column(children: [
        Container(
          color: C.bg,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 14,
            left: 20, right: 20, bottom: 14,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Patients', style: GoogleFonts.plusJakartaSans(
                  color: C.t1, fontSize: 22, fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: _showAddPatient,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(gradient: C.tealGrad,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: C.teal.withOpacity(0.2), blurRadius: 12, offset: const Offset(0,4))]),
                  child: Row(children: [
                    const Icon(Icons.person_add_outlined, color: C.bg, size: 16),
                    const SizedBox(width: 5),
                    Text('Add Patient', style: GoogleFonts.plusJakartaSans(
                        color: C.bg, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name, ID or phone...',
                prefixIcon: const Icon(Icons.search, color: C.t3, size: 20),
                suffixIcon: _query.isNotEmpty
                  ? GestureDetector(onTap: () => setState(() => _query = ''),
                      child: const Icon(Icons.close, color: C.t3, size: 18))
                  : null,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _FilterChip(label: 'All (${AppStore().patients.length})',
                    active: _filterClass == null, color: C.teal,
                    onTap: () => setState(() => _filterClass = null)),
                ...TumorClass.values.map((cls) => _FilterChip(
                  label: cls.label,
                  active: _filterClass == cls,
                  color: cls.color,
                  onTap: () => setState(() =>
                      _filterClass = _filterClass == cls ? null : cls),
                )),
              ]),
            ),
          ]),
        ),

        Expanded(child: filtered.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_query.isNotEmpty ? Icons.search_off : Icons.people_outline,
                  color: C.t3, size: 40),
              const SizedBox(height: 10),
              Text(_query.isNotEmpty ? 'No patients found' : 'No patients yet',
                  style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 14)),
              if (_query.isEmpty) ...[
                const SizedBox(height: 6),
                Text('Tap "Add Patient" to get started',
                    style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 12)),
              ],
            ]))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              physics: const BouncingScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (_, i) => PatientTile(
                filtered[i],
                onTap: () => _showDetail(context, filtered[i]),
              ),
            ),
        ),
      ]),
    );
  }

  void _showDetail(BuildContext context, Patient patient) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _PatientDetailSheet(patient: patient),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label; final bool active; final Color color; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? color.withOpacity(0.5) : C.divider),
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(
          color: active ? color : C.t3, fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
    ),
  );
}

class _PatientDetailSheet extends StatelessWidget {
  final Patient patient;
  const _PatientDetailSheet({required this.patient});

  @override
  Widget build(BuildContext context) {
    final latest = patient.scans.isNotEmpty ? patient.scans.first : null;
    return DraggableScrollableSheet(
      initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => ListView(controller: ctrl, children: [
        const SizedBox(height: 10),
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: C.divider, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    (latest?.result.color ?? C.teal).withOpacity(0.3),
                    (latest?.result.color ?? C.teal).withOpacity(0.1),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(
                  patient.name.split(' ').map((e) => e[0]).take(2).join(),
                  style: GoogleFonts.plusJakartaSans(
                      color: latest?.result.color ?? C.teal,
                      fontSize: 20, fontWeight: FontWeight.w700),
                )),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(patient.name, style: GoogleFonts.plusJakartaSans(
                    color: C.t1, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('${patient.id}  •  ${patient.age}y  •  ${patient.gender}',
                    style: GoogleFonts.spaceMono(color: C.t3, fontSize: 10)),
              ])),
              if (latest != null)
                ChipLabel(latest.result.isPositive
                    ? latest.result.label.toUpperCase() : 'CLEAR',
                    color: latest.result.color),
            ]),
            const SizedBox(height: 20),

            _infoRow('Date of Birth', patient.dob),
            _infoRow('Phone', patient.phone),
            _infoRow('Total Scans', '${patient.scans.length}'),
            if (latest != null) ...[
              _infoRow('Last Diagnosis', latest.result.label),
              _infoRow('Confidence', '${(latest.confidence * 100).toStringAsFixed(1)}%'),
              _infoRow('Last Scan', latest.fullTimestamp),
              _infoRow('Radiologist', latest.radiologist),
            ],

            if (patient.scans.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Scan History (${patient.scans.length})', style: GoogleFonts.plusJakartaSans(
                  color: C.t1, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...patient.scans.map((s) => ScanCard(s)),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.divider)),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: C.t3, size: 18),
                  const SizedBox(width: 10),
                  Text('No scans recorded yet',
                      style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 13)),
                ]),
              ),
            ],

            const SizedBox(height: 20),
            TealButton(
              label: 'New MRI Scan',
              icon: Icons.document_scanner_outlined,
              onTap: () {
                AppStore().selectPatient(patient);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${patient.name} selected — go to Scan tab'),
                  backgroundColor: C.teal, behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(11),
          border: Border.all(color: C.divider)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 12)),
        Text(value, style: GoogleFonts.plusJakartaSans(
            color: C.t1, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}
