import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../services/app_store.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  XFile? _pickedFile;
  Uint8List? _webImageBytes;
  bool _analyzing = false;
  bool _hasResult = false;
  TumorClass? _predictedClass;
  Map<TumorClass, double>? _probs;
  String? _errorMessage;
  ScanRecord? _lastRecord;

  Patient? get _selectedPatient => AppStore().selectedPatient;
  bool get _hasImage => _pickedFile != null;

  late final AnimationController _scanLine = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  late final AnimationController _resultEntry = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));

  final _analyzeSteps = [
    'Uploading image to server...',
    'Preprocessing image...',
    'Extracting CNN features...',
    'Running 4-class classifier...',
    'Glioma  /  Meningioma  /  Pituitary  /  No Tumor',
    'Computing confidence scores...',
    'Saving to scan history...',
  ];
  int _analyzeStep = 0;

  @override
  void dispose() {
    _scanLine.dispose();
    _resultEntry.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    Uint8List? bytes;
    if (kIsWeb) bytes = await picked.readAsBytes();
    setState(() {
      _pickedFile = picked;
      _webImageBytes = bytes;
      _hasResult = false;
      _predictedClass = null;
      _probs = null;
      _errorMessage = null;
      _lastRecord = null;
    });
  }

  void _showPickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: C.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Select MRI Image', style: GoogleFonts.plusJakartaSans(
                color: C.t1, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _PickerOption(
                icon: Icons.photo_library_outlined, label: 'Gallery',
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              )),
              const SizedBox(width: 12),
              Expanded(child: _PickerOption(
                icon: Icons.camera_alt_outlined, label: 'Camera',
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showPatientSelector() {
    final store = AppStore();
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: C.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('Select Patient', style: GoogleFonts.plusJakartaSans(
                  color: C.t1, fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showAddPatientDialog();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: C.tealGrad, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.add, color: C.bg, size: 14),
                    const SizedBox(width: 4),
                    Text('New', style: GoogleFonts.plusJakartaSans(
                        color: C.bg, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(child: ListView.builder(
            controller: ctrl,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: store.patients.length,
            itemBuilder: (_, i) {
              final p = store.patients[i];
              final selected = _selectedPatient?.id == p.id;
              return GestureDetector(
                onTap: () {
                  store.selectPatient(p);
                  setState(() {});
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected ? C.tealGlow : C.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? C.tealBorder : C.divider),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: C.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(
                        p.name.split(' ').map((e) => e[0]).take(2).join(),
                        style: GoogleFonts.plusJakartaSans(
                            color: C.teal, fontSize: 13, fontWeight: FontWeight.w700),
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: GoogleFonts.plusJakartaSans(
                          color: C.t1, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${p.id}  •  ${p.age}y  •  ${p.gender}',
                          style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9)),
                    ])),
                    if (selected) const Icon(Icons.check_circle, color: C.teal, size: 20),
                  ]),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }

  void _showAddPatientDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final dobCtrl = TextEditingController();
    int age = 30;
    String gender = 'Male';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: C.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add New Patient', style: GoogleFonts.plusJakartaSans(
                  color: C.t1, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              _dlgLabel('FULL NAME'),
              const SizedBox(height: 6),
              _dlgField(nameCtrl, 'Kofi Mensah', Icons.person_outline),
              const SizedBox(height: 14),

              _dlgLabel('PHONE NUMBER'),
              const SizedBox(height: 6),
              _dlgField(phoneCtrl, '+233 24 000 0000', Icons.phone_outlined,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 14),

              _dlgLabel('DATE OF BIRTH'),
              const SizedBox(height: 6),
              _dlgField(dobCtrl, 'e.g. 15 Jan 1980', Icons.cake_outlined),
              const SizedBox(height: 14),

              _dlgLabel('AGE'),
              const SizedBox(height: 6),
              Row(children: [
                GestureDetector(
                  onTap: () => setDlg(() { if (age > 1) age--; }),
                  child: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: C.divider)),
                    child: const Icon(Icons.remove, color: C.teal, size: 18)),
                ),
                Expanded(child: Center(child: Text('$age',
                    style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 18, fontWeight: FontWeight.w700)))),
                GestureDetector(
                  onTap: () => setDlg(() => age++),
                  child: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: C.divider)),
                    child: const Icon(Icons.add, color: C.teal, size: 18)),
                ),
              ]),
              const SizedBox(height: 14),

              _dlgLabel('GENDER'),
              const SizedBox(height: 6),
              Row(children: ['Male', 'Female', 'Other'].map((g) => Expanded(child: GestureDetector(
                onTap: () => setDlg(() => gender = g),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: gender == g ? C.tealGlow : C.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: gender == g ? C.tealBorder : C.divider),
                  ),
                  child: Center(child: Text(g, style: GoogleFonts.plusJakartaSans(
                      color: gender == g ? C.teal : C.t2, fontSize: 12,
                      fontWeight: gender == g ? FontWeight.w600 : FontWeight.normal))),
                ),
              ))).toList()),

              const SizedBox(height: 24),
              TealButton(
                label: 'ADD PATIENT',
                icon: Icons.person_add_outlined,
                onTap: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final p = AppStore().addPatient(
                    name: nameCtrl.text.trim(),
                    age: age,
                    gender: gender,
                    phone: phoneCtrl.text.trim().isEmpty ? 'N/A' : phoneCtrl.text.trim(),
                    dob: dobCtrl.text.trim().isEmpty ? 'N/A' : dobCtrl.text.trim(),
                  );
                  AppStore().selectPatient(p);
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${p.name} added successfully'),
                    backgroundColor: C.ok,
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _dlgLabel(String t) => Text(t,
      style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9, letterSpacing: 1.2));

  Widget _dlgField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType keyboard = TextInputType.text}) =>
    TextField(
      controller: ctrl, keyboardType: keyboard,
      style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: C.teal, size: 18),
      ),
    );

  Future<void> _analyze() async {
    if (_pickedFile == null) return;
    if (_selectedPatient == null) {
      _showPatientSelector();
      return;
    }

    setState(() {
      _analyzing = true; _hasResult = false;
      _errorMessage = null; _analyzeStep = 0;
    });

    Future<void> animLoop() async {
      for (int i = 1; i < _analyzeSteps.length - 1; i++) {
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        setState(() => _analyzeStep = i);
      }
    }

    Future<Map<String, dynamic>> apiFuture() async {
      if (kIsWeb) {
        final bytes = _webImageBytes ?? await _pickedFile!.readAsBytes();
        return ApiService.predictBrainTumorWeb(bytes, _pickedFile!.name);
      } else {
        return ApiService.predictBrainTumor(File(_pickedFile!.path));
      }
    }

    final results = await Future.wait([apiFuture(), animLoop()]);
    final Map<String, dynamic> result = results[0] as Map<String, dynamic>;

    if (!mounted) return;

    if (result.containsKey('error')) {
      setState(() { _analyzing = false; _errorMessage = result['error']; });
      return;
    }

    final className = result['class'] as String;
    final allProbs  = result['all_probabilities'] as List<dynamic>;
    final probMap   = ApiService.parseProbabilities(allProbs);
    final predicted = _classFromString(className);
    final enumProbs = {
      TumorClass.glioma:     probMap['glioma']     ?? 0.0,
      TumorClass.meningioma: probMap['meningioma']  ?? 0.0,
      TumorClass.pituitary:  probMap['pituitary']   ?? 0.0,
      TumorClass.noTumor:    probMap['notumor']     ?? probMap['no_tumor'] ?? 0.0,
    };

    // Save to store — updates dashboard, patients, reports automatically
    final record = AppStore().addScanResult(
      patient: _selectedPatient!,
      result: predicted,
      confidence: result['confidence'] as double,
      probabilities: enumProbs,
    );

    setState(() {
      _analyzeStep = _analyzeSteps.length - 1;
      _analyzing = false;
      _hasResult = true;
      _predictedClass = predicted;
      _probs = enumProbs;
      _lastRecord = record;
    });
    _resultEntry.forward(from: 0);
  }

  TumorClass _classFromString(String s) {
    // Class names come from labels.json saved during training
    // Training folder names: glioma, meningioma, notumor, pituitary
    switch (s.trim().toLowerCase()) {
      case 'glioma':     return TumorClass.glioma;
      case 'meningioma': return TumorClass.meningioma;
      case 'pituitary':  return TumorClass.pituitary;
      case 'notumor':    return TumorClass.noTumor;   // matches training folder
      case 'no_tumor':   return TumorClass.noTumor;   // fallback
      case 'no tumor':   return TumorClass.noTumor;   // fallback
      default:
        print('[NeuroScan] Unknown class: $s — defaulting to noTumor');
        return TumorClass.noTumor;
    }
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(_webImageBytes!, width: double.infinity, height: 210, fit: BoxFit.cover);
    } else if (!kIsWeb && _pickedFile != null) {
      return Image.file(File(_pickedFile!.path), width: double.infinity, height: 210, fit: BoxFit.cover);
    }
    return Container(width: double.infinity, height: 210, color: C.card,
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.image_outlined, color: C.teal, size: 48),
        SizedBox(height: 8),
        Text('Image ready', style: TextStyle(color: C.teal, fontSize: 13)),
      ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.surface, elevation: 0,
        title: Text('MRI Analysis', style: GoogleFonts.plusJakartaSans(
            color: C.t1, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: C.tealGlow, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: C.tealBorder)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 5, height: 5,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: C.ok)),
              const SizedBox(width: 6),
              Text('CNN v3.2 • 4-Class',
                  style: GoogleFonts.spaceMono(color: C.teal, fontSize: 9, letterSpacing: .8)),
            ]),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(children: [

          // Upload zone
          GestureDetector(
            onTap: _analyzing ? null : _showPickerDialog,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity, height: 210,
              decoration: BoxDecoration(
                color: _hasImage ? C.card : C.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _hasImage ? C.tealBorder : C.divider,
                    width: _hasImage ? 1.5 : 1),
              ),
              child: _hasImage
                  ? Stack(alignment: Alignment.center, children: [
                      ClipRRect(borderRadius: BorderRadius.circular(19),
                          child: _buildImagePreview()),
                      Positioned(top: 12, left: 14, child: ChipLabel('MRI SCAN', color: C.teal)),
                      Positioned(top: 12, right: 14, child: ChipLabel('READY', color: C.ok)),
                      if (!_analyzing) Positioned(
                        bottom: 12, right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: C.bg.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('Tap to change',
                              style: GoogleFonts.spaceMono(color: C.t2, fontSize: 9)),
                        ),
                      ),
                      if (_analyzing) AnimatedBuilder(
                        animation: _scanLine,
                        builder: (_, __) {
                          final y = 20 + _scanLine.value * 170;
                          return Positioned(top: y, left: 0, right: 0,
                            child: Container(height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [
                                Colors.transparent,
                                C.teal.withOpacity(.9), C.cyan,
                                C.teal.withOpacity(.9), Colors.transparent,
                              ]))));
                        },
                      ),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 56, height: 56,
                        decoration: BoxDecoration(color: C.tealGlow, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.upload_file_outlined, color: C.teal, size: 26)),
                      const SizedBox(height: 12),
                      Text('Tap to upload MRI scan', style: GoogleFonts.plusJakartaSans(
                          color: C.t1, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 5),
                      Text('Gallery or Camera  ·  PNG  ·  JPG',
                          style: GoogleFonts.spaceMono(color: C.t3, fontSize: 10, letterSpacing: .8)),
                    ]),
            ),
          ),

          const SizedBox(height: 14),

          // Patient selector bar
          GestureDetector(
            onTap: _analyzing ? null : _showPatientSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: C.card, borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _selectedPatient != null ? C.tealBorder : C.divider),
              ),
              child: Row(children: [
                Icon(_selectedPatient != null ? Icons.person : Icons.person_search_outlined,
                    color: C.teal, size: 18),
                const SizedBox(width: 10),
                Expanded(child: _selectedPatient != null
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${_selectedPatient!.id}  •  ${_selectedPatient!.name}  •  ${_selectedPatient!.age}y  •  ${_selectedPatient!.gender}',
                          style: GoogleFonts.plusJakartaSans(color: C.t1, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('Tap to change patient',
                          style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 11)),
                    ])
                  : Text('Select patient for this scan',
                      style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 13)),
                ),
                Icon(_selectedPatient != null ? Icons.edit_outlined : Icons.arrow_forward_ios_rounded,
                    color: C.t3, size: 14),
              ]),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _ErrorCard(message: _errorMessage!),
          ],

          if (_hasImage && !_analyzing && !_hasResult) ...[
            const SizedBox(height: 14),
            TealButton(
              label: _selectedPatient == null ? 'SELECT PATIENT & ANALYSE' : 'ANALYSE WITH AI',
              icon: Icons.psychology_outlined,
              onTap: _analyze,
            ),
          ],

          if (_analyzing) ...[
            const SizedBox(height: 14),
            _AnalyzingCard(step: _analyzeStep, steps: _analyzeSteps, ctrl: _scanLine),
          ],

          if (_hasResult && _predictedClass != null) ...[
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: _resultEntry,
              builder: (_, __) => Opacity(
                opacity: CurvedAnimation(parent: _resultEntry, curve: Curves.easeOut).value,
                child: Transform.translate(
                  offset: Offset(0, 22 * (1 - _resultEntry.value)),
                  child: _ResultSection(
                    cls: _predictedClass!, probs: _probs!,
                    record: _lastRecord,
                    onNewScan: () => setState(() {
                      _pickedFile = null; _webImageBytes = null;
                      _hasResult = false; _predictedClass = null;
                      _probs = null; _lastRecord = null; _errorMessage = null;
                    }),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          _ClassInfoGrid(),
        ]),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _PickerOption({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.divider)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: C.teal, size: 28),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.plusJakartaSans(
            color: C.t1, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: C.errGlow, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.err.withOpacity(0.4))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.error_outline, color: C.err, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Error', style: GoogleFonts.plusJakartaSans(
            color: C.err, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(message, style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 11)),
      ])),
    ]),
  );
}

class _AnalyzingCard extends StatelessWidget {
  final int step; final List<String> steps; final AnimationController ctrl;
  const _AnalyzingCard({required this.step, required this.steps, required this.ctrl});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.tealBorder)),
    child: Column(children: [
      AnimatedBuilder(animation: ctrl, builder: (_, __) => Container(
        width: 50, height: 50,
        decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: C.teal.withOpacity(.3 + ctrl.value * .4), width: 2)),
        child: const Icon(Icons.psychology_outlined, color: C.teal, size: 24),
      )),
      const SizedBox(height: 12),
      Text('AI Analysis in Progress', style: GoogleFonts.plusJakartaSans(
          color: C.t1, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(steps[step], style: GoogleFonts.spaceMono(
          color: C.teal, fontSize: 10, letterSpacing: .5), textAlign: TextAlign.center),
      const SizedBox(height: 14),
      ClipRRect(borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          backgroundColor: C.divider, minHeight: 3,
          value: (step + 1) / steps.length,
          valueColor: const AlwaysStoppedAnimation(C.teal),
        )),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: TumorClass.values.map((cls) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: cls.color.withOpacity(step >= 3 ? 0.12 : 0.04),
                borderRadius: BorderRadius.circular(6)),
            child: Text(cls.label, style: GoogleFonts.spaceMono(
                color: cls.color.withOpacity(step >= 3 ? 1 : 0.3), fontSize: 9)),
          ),
        )).toList()),
    ]),
  );
}

class _ResultSection extends StatelessWidget {
  final TumorClass cls;
  final Map<TumorClass, double> probs;
  final ScanRecord? record;
  final VoidCallback onNewScan;
  const _ResultSection({required this.cls, required this.probs, this.record, required this.onNewScan});

  @override
  Widget build(BuildContext context) => Column(children: [
    // Saved badge
    if (record != null) Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: C.ok.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.ok.withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.check_circle_outline, color: C.ok, size: 16),
        const SizedBox(width: 8),
        Text('Saved as ${record!.scanId}  •  ${record!.fullTimestamp}',
            style: GoogleFonts.spaceMono(color: C.ok, fontSize: 9, letterSpacing: .5)),
      ]),
    ),

    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [cls.color.withOpacity(0.08), cls.color.withOpacity(0.03)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cls.color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ChipLabel(cls.isPositive ? '⚠  TUMOR DETECTED' : '✓  CLEAR', color: cls.color),
          const Spacer(),
          ChipLabel('REAL-TIME AI', color: C.info),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cls.label, style: GoogleFonts.plusJakartaSans(
                color: C.t1, fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 6),
            Text('MRI Scan • ${cls.isPositive ? "Positive" : "Negative"}',
                style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 13)),
            const SizedBox(height: 12),
            Text(cls.description, style: GoogleFonts.plusJakartaSans(
                color: C.t2, fontSize: 12, height: 1.55)),
          ])),
          const SizedBox(width: 16),
          ConfidenceGauge(value: probs[cls]!, color: cls.color, size: 88),
        ]),
      ]),
    ),
    const SizedBox(height: 14),

    // Probabilities
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: C.cardGrad, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('CLASS PROBABILITIES', style: GoogleFonts.spaceMono(
              color: C.t3, fontSize: 9, letterSpacing: 1.5)),
          const SizedBox(width: 8),
          const ChipLabel('4-CLASS CNN', color: C.info),
        ]),
        const SizedBox(height: 14),
        ...TumorClass.values.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(width: 88, child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(
                  color: c.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text(c.label, style: GoogleFonts.plusJakartaSans(
                  color: c == cls ? C.t1 : C.t2, fontSize: 12,
                  fontWeight: c == cls ? FontWeight.w600 : FontWeight.normal)),
            ])),
            Expanded(child: Stack(children: [
              Container(height: 5, decoration: BoxDecoration(
                  color: C.divider, borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(widthFactor: probs[c]!,
                child: Container(height: 5, decoration: BoxDecoration(
                  color: c.color, borderRadius: BorderRadius.circular(3),
                  boxShadow: [BoxShadow(color: c.color.withOpacity(.4), blurRadius: 5)],
                ))),
            ])),
            const SizedBox(width: 8),
            SizedBox(width: 44, child: Text('${(probs[c]! * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceMono(
                  color: c == cls ? c.color : C.t3, fontSize: 11,
                  fontWeight: c == cls ? FontWeight.w700 : FontWeight.normal))),
          ]),
        )),
      ]),
    ),
    const SizedBox(height: 14),

    // Action buttons
    Row(children: [
      Expanded(child: TealButton(label: 'New Scan', icon: Icons.add_a_photo_outlined,
          height: 48, onTap: onNewScan)),
      const SizedBox(width: 10),
      Expanded(child: _ActionBtn(label: 'Share',
        icon: Icons.share_outlined,
        onTap: () => _shareReport(context),
      )),
      const SizedBox(width: 10),
      Expanded(child: _ActionBtn(label: 'Refer',
        icon: Icons.send_outlined,
        onTap: () => _referPatient(context),
      )),
    ]),
  ]);

  void _shareReport(BuildContext context) {
    if (record == null) return;
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: C.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.share_outlined, color: C.teal, size: 32),
          const SizedBox(height: 12),
          Text('Share Report', style: GoogleFonts.plusJakartaSans(
              color: C.t1, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${record!.scanId} — ${record!.patientName}\n${record!.result.label} (${(record!.confidence * 100).toStringAsFixed(1)}%)',
              style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text('Share via', style: GoogleFonts.spaceMono(color: C.t3, fontSize: 9, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _shareOption(context, Icons.email_outlined, 'Email'),
            _shareOption(context, Icons.message_outlined, 'SMS'),
            _shareOption(context, Icons.print_outlined, 'Print'),
            _shareOption(context, Icons.content_copy_outlined, 'Copy'),
          ]),
        ]),
      ),
    ));
  }

  Widget _shareOption(BuildContext ctx, IconData icon, String label) =>
    GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Report shared via $label'),
          backgroundColor: C.ok, behavior: SnackBarBehavior.floating,
        ));
      },
      child: Column(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.divider)),
          child: Icon(icon, color: C.teal, size: 22)),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 11)),
      ]),
    );

  void _referPatient(BuildContext context) {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: C.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Refer Patient', style: GoogleFonts.plusJakartaSans(
              color: C.t1, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Select department for referral:',
              style: GoogleFonts.plusJakartaSans(color: C.t2, fontSize: 13)),
          const SizedBox(height: 16),
          ...['Oncology', 'Neurosurgery', 'Radiology', 'Endocrinology'].map((dept) =>
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Referral sent to $dept'),
                  backgroundColor: C.ok, behavior: SnackBarBehavior.floating,
                ));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.divider)),
                child: Row(children: [
                  const Icon(Icons.local_hospital_outlined, color: C.teal, size: 18),
                  const SizedBox(width: 10),
                  Text(dept, style: GoogleFonts.plusJakartaSans(
                      color: C.t1, fontSize: 13, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, color: C.t3, size: 14),
                ]),
              ),
            ),
          ),
        ]),
      ),
    ));
  }
}

class _ActionBtn extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback? onTap;
  const _ActionBtn({required this.label, required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(height: 48,
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.divider)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: C.t2, size: 16),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.plusJakartaSans(
            color: C.t2, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

class _ClassInfoGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Detectable Classes', style: GoogleFonts.plusJakartaSans(
          color: C.t1, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      GridView.count(crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.1,
        children: TumorClass.values.map((cls) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(gradient: C.cardGrad, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cls.color.withOpacity(0.2))),
          child: Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: cls.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(cls.icon, color: cls.color, size: 16)),
            const SizedBox(width: 9),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(cls.label, style: GoogleFonts.plusJakartaSans(
                      color: C.t1, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(cls.isPositive ? 'Positive' : 'Negative',
                      style: GoogleFonts.spaceMono(color: cls.color, fontSize: 9)),
                ]),
          ]),
        )).toList()),
    ],
  );
}
