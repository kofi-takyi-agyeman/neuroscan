import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/theme.dart';

// ── Tumor class ───────────────────────────────────────────────
enum TumorClass { glioma, meningioma, pituitary, noTumor }

extension TumorClassX on TumorClass {
  String get label {
    switch (this) {
      case TumorClass.glioma:     return 'Glioma';
      case TumorClass.meningioma: return 'Meningioma';
      case TumorClass.pituitary:  return 'Pituitary';
      case TumorClass.noTumor:    return 'No Tumor';
    }
  }

  Color get color {
    switch (this) {
      case TumorClass.glioma:     return C.glioma;
      case TumorClass.meningioma: return C.mening;
      case TumorClass.pituitary:  return C.pitu;
      case TumorClass.noTumor:    return C.noTumor;
    }
  }

  bool get isPositive => this != TumorClass.noTumor;

  String get description {
    switch (this) {
      case TumorClass.glioma:
        return 'Malignant tumor arising from glial cells. Requires immediate oncology referral.';
      case TumorClass.meningioma:
        return 'Usually benign tumor from meninges. Monitor growth; surgical evaluation recommended.';
      case TumorClass.pituitary:
        return 'Adenoma of the pituitary gland. Endocrinology and neurosurgery consult advised.';
      case TumorClass.noTumor:
        return 'No tumor detected. Scan is within normal parameters.';
    }
  }

  IconData get icon {
    switch (this) {
      case TumorClass.glioma:     return Icons.warning_rounded;
      case TumorClass.meningioma: return Icons.error_outline_rounded;
      case TumorClass.pituitary:  return Icons.info_outline_rounded;
      case TumorClass.noTumor:    return Icons.check_circle_outline_rounded;
    }
  }
}

// ── Patient ───────────────────────────────────────────────────
class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String dob;
  final List<ScanRecord> scans;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.dob,
    required this.scans,
  });

  Patient copyWith({
    String? id, String? name, int? age, String? gender,
    String? phone, String? dob, List<ScanRecord>? scans,
  }) => Patient(
    id: id ?? this.id, name: name ?? this.name, age: age ?? this.age,
    gender: gender ?? this.gender, phone: phone ?? this.phone,
    dob: dob ?? this.dob, scans: scans ?? this.scans,
  );

  Patient copyWithScan(ScanRecord scan) =>
      copyWith(scans: [scan, ...scans]);
}

// ── Scan record ───────────────────────────────────────────────
class ScanRecord {
  final String scanId;
  final String patientId;
  final String patientName;
  final TumorClass result;
  final double confidence;
  final Map<TumorClass, double> probabilities;
  final DateTime dateTime;
  final String radiologist;

  const ScanRecord({
    required this.scanId,
    required this.patientId,
    required this.patientName,
    required this.result,
    required this.confidence,
    required this.probabilities,
    required this.dateTime,
    required this.radiologist,
  });

  /// Human-readable timestamp: "Today 10:24 AM", "Yesterday", "12 Mar"
  String get timestamp {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scanDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(scanDay).inDays;
    final time = DateFormat('h:mm a').format(dateTime);
    if (diff == 0) return 'Today $time';
    if (diff == 1) return 'Yesterday $time';
    return DateFormat('d MMM').format(dateTime);
  }

  String get fullTimestamp => DateFormat('d MMM yyyy, h:mm a').format(dateTime);
}
