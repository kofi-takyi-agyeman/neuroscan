import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Role definitions
class UserRole {
  static const doctor      = 'Doctor';
  static const radiologist = 'Radiologist';
  static const nurse       = 'Nurse';
  static const admin       = 'Admin';
  static const patient     = 'Patient';
  static const all         = [doctor, radiologist, nurse, admin, patient];

  static RolePermissions permissionsFor(String role) {
    switch (role) {
      case doctor:
        return RolePermissions(
          canScan: true, canViewAllPatients: true, canAddPatients: true,
          canExportReports: true, canReferPatients: true, canViewReports: true,
          dashboardTitle: 'Clinical Dashboard', scanLabel: 'Order MRI Analysis',
        );
      case radiologist:
        return RolePermissions(
          canScan: true, canViewAllPatients: true, canAddPatients: false,
          canExportReports: true, canReferPatients: false, canViewReports: true,
          dashboardTitle: 'Radiology Dashboard', scanLabel: 'Read MRI Scan',
        );
      case nurse:
        return RolePermissions(
          canScan: false, canViewAllPatients: true, canAddPatients: true,
          canExportReports: false, canReferPatients: false, canViewReports: false,
          dashboardTitle: 'Nursing Dashboard', scanLabel: 'View Scans',
        );
      case admin:
        return RolePermissions(
          canScan: false, canViewAllPatients: true, canAddPatients: true,
          canExportReports: true, canReferPatients: false, canViewReports: true,
          dashboardTitle: 'Admin Dashboard', scanLabel: 'Manage Scans',
        );
      case patient:
        return RolePermissions(
          canScan: false, canViewAllPatients: false, canAddPatients: false,
          canExportReports: false, canReferPatients: false, canViewReports: false,
          dashboardTitle: 'My Health', scanLabel: 'My Scans',
        );
      default:
        return RolePermissions(
          canScan: false, canViewAllPatients: false, canAddPatients: false,
          canExportReports: false, canReferPatients: false, canViewReports: false,
          dashboardTitle: 'Dashboard', scanLabel: 'Scan',
        );
    }
  }
}

class RolePermissions {
  final bool canScan, canViewAllPatients, canAddPatients;
  final bool canExportReports, canReferPatients, canViewReports;
  final String dashboardTitle, scanLabel;
  const RolePermissions({
    required this.canScan, required this.canViewAllPatients,
    required this.canAddPatients, required this.canExportReports,
    required this.canReferPatients, required this.canViewReports,
    required this.dashboardTitle, required this.scanLabel,
  });
}

/// Auth service using shared_preferences — works on Web, Android & iOS
class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const _usersKey   = 'neuroscan_users_v2';
  static const _sessionKey = 'neuroscan_session_v2';

  List<Map<String, dynamic>> _users   = [];
  Map<String, dynamic>?      _currentUser;
  bool _initialised = false;

  Map<String, dynamic>? get currentUser  => _currentUser;
  bool                  get isLoggedIn   => _currentUser != null;
  RolePermissions       get permissions  =>
      UserRole.permissionsFor(_currentUser?['role'] ?? '');

  // ── Initialise — call once at app start ───────────────────
  // Already called by SplashScreen. Safe to call multiple times.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    final prefs = await SharedPreferences.getInstance();

    // Load user list
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null && usersJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(usersJson) as List<dynamic>;
        _users = decoded
            .map((u) => Map<String, dynamic>.from(u as Map))
            .toList();
      } catch (_) {
        _users = [];
      }
    }

    // Seed demo accounts if empty
    if (_users.isEmpty) {
      _users = _demoAccounts();
      await _saveUsers(prefs);
    }

    // Restore session
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      try {
        final session = jsonDecode(sessionJson) as Map<String, dynamic>;
        final userId  = session['id'] as String?;
        if (userId != null) {
          final found = _users.where((u) => u['id'] == userId).toList();
          if (found.isNotEmpty) _currentUser = found.first;
        }
      } catch (_) {}
    }
  }

  // ── Demo accounts ─────────────────────────────────────────
  static List<Map<String, dynamic>> _demoAccounts() => [
    {
      'id': 'USR-0001', 'name': 'Dr. Ama Boateng',
      'email': 'doctor@neuroscan.gh', 'password': '12345678',
      'role': 'Doctor', 'specialty': 'Neurology',
      'hospital': 'Korle Bu Teaching Hospital', 'phone': '+233 24 111 2222',
    },
    {
      'id': 'USR-0002', 'name': 'Dr. Yaw Darko',
      'email': 'radiologist@neuroscan.gh', 'password': '12345678',
      'role': 'Radiologist', 'specialty': 'Radiology',
      'hospital': 'Komfo Anokye Teaching Hospital', 'phone': '+233 20 333 4444',
    },
    {
      'id': 'USR-0003', 'name': 'Nurse Akosua Mensah',
      'email': 'nurse@neuroscan.gh', 'password': '12345678',
      'role': 'Nurse', 'specialty': 'General',
      'hospital': 'Korle Bu Teaching Hospital', 'phone': '+233 27 555 6666',
    },
  ];

  List<Map<String, String>> get demoAccounts => _users
      .take(3)
      .map((u) => {
            'name':     u['name']     as String,
            'email':    u['email']    as String,
            'password': u['password'] as String,
            'role':     u['role']     as String,
          })
      .toList();

  // ── Save helpers ─────────────────────────────────────────
  Future<void> _saveUsers([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setString(_usersKey, jsonEncode(_users));
  }

  Future<void> _saveSession(Map<String, dynamic>? user) async {
    final p = await SharedPreferences.getInstance();
    if (user != null) {
      await p.setString(_sessionKey, jsonEncode({
        'id':   user['id'],
        'name': user['name'],
        'role': user['role'],
      }));
    } else {
      await p.remove(_sessionKey);
    }
  }

  // ── Login ─────────────────────────────────────────────────
  Future<AuthResult> login(String email, String password) async {
    await init(); // ensure loaded
    await Future.delayed(const Duration(milliseconds: 700));

    final user = _users.where((u) =>
      u['email'].toString().toLowerCase() == email.trim().toLowerCase() &&
      u['password'] == password
    ).firstOrNull;

    if (user == null) {
      final emailExists = _users.any((u) =>
          u['email'].toString().toLowerCase() == email.trim().toLowerCase());
      if (emailExists) {
        return AuthResult.failure('Incorrect password. Please try again.');
      }
      return AuthResult.failure('No account found with that email address.');
    }

    _currentUser = user;
    await _saveSession(user);
    return AuthResult.success(user);
  }

  // ── Sign up ───────────────────────────────────────────────
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    required String hospital,
    required String specialty,
    required String phone,
  }) async {
    await init();
    await Future.delayed(const Duration(milliseconds: 800));

    final exists = _users.any((u) =>
        u['email'].toString().toLowerCase() == email.trim().toLowerCase());
    if (exists) {
      return AuthResult.failure('An account with this email already exists.');
    }

    final newUser = {
      'id':       'USR-${(_users.length + 1).toString().padLeft(4, '0')}',
      'name':     name.trim(),
      'email':    email.trim().toLowerCase(),
      'password': password,
      'role':     role,
      'specialty': specialty.isEmpty ? role : specialty,
      'hospital': hospital.trim(),
      'phone':    phone.trim(),
    };

    _users.add(newUser);
    await _saveUsers();       // ✅ persist to shared_preferences
    _currentUser = newUser;
    await _saveSession(newUser);
    return AuthResult.success(newUser);
  }

  // ── Forgot password ───────────────────────────────────────
  Future<AuthResult> sendResetLink(String email) async {
    await init();
    await Future.delayed(const Duration(milliseconds: 700));
    final exists = _users.any((u) =>
        u['email'].toString().toLowerCase() == email.trim().toLowerCase());
    if (!exists) {
      return AuthResult.failure('No account found with that email address.');
    }
    return AuthResult.success({'email': email});
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> logout() async {
    _currentUser = null;
    await _saveSession(null);
  }
}

class AuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;
  AuthResult._({required this.success, this.error, this.data});
  factory AuthResult.success(Map<String, dynamic> data) =>
      AuthResult._(success: true, data: data);
  factory AuthResult.failure(String error) =>
      AuthResult._(success: false, error: error);
}
