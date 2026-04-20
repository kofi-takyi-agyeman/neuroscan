import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

/// Single source of truth for all live app data.
/// All screens listen to this — changes propagate everywhere instantly.
class AppStore extends ChangeNotifier {
  static final AppStore _instance = AppStore._();
  factory AppStore() => _instance;
  AppStore._();

  // ── Patients ──────────────────────────────────────────────
  final List<Patient> _patients = [
    Patient(
      id: 'P-0091', name: 'Kofi Mensah', age: 52, gender: 'Male',
      phone: '+233 24 123 4567', dob: '12 Mar 1972',
      scans: [],
    ),
    Patient(
      id: 'P-0087', name: 'Abena Serwaa', age: 38, gender: 'Female',
      phone: '+233 20 987 6543', dob: '05 Jul 1986',
      scans: [],
    ),
    Patient(
      id: 'P-0083', name: 'Kwame Asante', age: 64, gender: 'Male',
      phone: '+233 27 456 7890', dob: '19 Jan 1960',
      scans: [],
    ),
    Patient(
      id: 'P-0080', name: 'Efua Owusu', age: 45, gender: 'Female',
      phone: '+233 26 234 5678', dob: '30 Sep 1979',
      scans: [],
    ),
    Patient(
      id: 'P-0076', name: 'Nana Adjei', age: 59, gender: 'Male',
      phone: '+233 24 876 5432', dob: '14 Feb 1965',
      scans: [],
    ),
  ];

  // ── Scan history ──────────────────────────────────────────
  final List<ScanRecord> _scans = [];

  List<Patient> get patients => List.unmodifiable(_patients);
  List<ScanRecord> get scans => List.unmodifiable(_scans);

  // Most recent scans first
  List<ScanRecord> get recentScans =>
      _scans.reversed.toList();

  // Updated stats based on real scan data
  int get totalScans => _scans.length;
  int get positiveScans => _scans.where((s) => s.result.isPositive).length;

  Map<TumorClass, int> get classBreakdown {
    final map = {for (var c in TumorClass.values) c: 0};
    for (final s in _scans) {
      map[s.result] = (map[s.result] ?? 0) + 1;
    }
    return map;
  }

  // Weekly scan counts for the current week (Mon=0..Sun=6)
  List<int> get weeklyTotal {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return _scans.where((s) {
        final d = s.dateTime;
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).length;
    });
  }

  List<int> get weeklyPositive {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return _scans.where((s) {
        final d = s.dateTime;
        return d.year == day.year && d.month == day.month &&
            d.day == day.day && s.result.isPositive;
      }).length;
    });
  }

  // ── Add scan result ───────────────────────────────────────
  ScanRecord addScanResult({
    required Patient patient,
    required TumorClass result,
    required double confidence,
    required Map<TumorClass, double> probabilities,
  }) {
    final user = AuthService().currentUser;
    final scanId = 'SCN-${(5000 + _scans.length).toString()}';
    final now = DateTime.now();

    final record = ScanRecord(
      scanId: scanId,
      patientId: patient.id,
      patientName: patient.name,
      result: result,
      confidence: confidence,
      probabilities: probabilities,
      dateTime: now,
      radiologist: user?['name'] ?? 'Dr. Unknown',
    );

    _scans.add(record);

    // Attach to patient
    final idx = _patients.indexWhere((p) => p.id == patient.id);
    if (idx != -1) {
      _patients[idx] = _patients[idx].copyWithScan(record);
    }

    notifyListeners();
    return record;
  }

  // ── Add patient ───────────────────────────────────────────
  Patient addPatient({
    required String name,
    required int age,
    required String gender,
    required String phone,
    required String dob,
  }) {
    final id = 'P-${(100 + _patients.length).toString().padLeft(4, '0')}';
    final patient = Patient(
      id: id, name: name, age: age,
      gender: gender, phone: phone, dob: dob, scans: [],
    );
    _patients.insert(0, patient);
    notifyListeners();
    return patient;
  }

  // ── Update patient ────────────────────────────────────────
  void updatePatient(Patient updated) {
    final idx = _patients.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _patients[idx] = updated;
      notifyListeners();
    }
  }

  // ── Selected patient for scan ─────────────────────────────
  Patient? selectedPatient;

  void selectPatient(Patient p) {
    selectedPatient = p;
    notifyListeners();
  }

  void clearSelectedPatient() {
    selectedPatient = null;
    notifyListeners();
  }
}
