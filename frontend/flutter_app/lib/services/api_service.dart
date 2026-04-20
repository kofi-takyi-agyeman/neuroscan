import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Web (Chrome) = localhost | Android emulator = 10.0.2.2 | Physical device = LAN IP
  static const String baseUrl = "http://localhost:8000";

  static MediaType _mimeFromName(String filename) {
    final n = filename.toLowerCase();
    if (n.endsWith('.png'))               return MediaType('image', 'png');
    if (n.endsWith('.bmp'))               return MediaType('image', 'bmp');
    if (n.endsWith('.tiff')||n.endsWith('.tif')) return MediaType('image', 'tiff');
    return MediaType('image', 'jpeg');
  }

  static String _safeFilename(String filename) {
    final n = filename.toLowerCase();
    if (n.endsWith('.png')||n.endsWith('.jpg')||n.endsWith('.jpeg')||
        n.endsWith('.bmp')||n.endsWith('.tiff')||n.endsWith('.tif')) return filename;
    return '$filename.jpg';
  }

  // ── Mobile ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> predictBrainTumor(File imageFile) async {
    try {
      final filename = imageFile.path.split('/').last.split('\\').last;
      final safeName = _safeFilename(filename);
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/predict"));
      request.files.add(await http.MultipartFile.fromPath(
        'image', imageFile.path,
        filename: safeName, contentType: _mimeFromName(safeName),
      ));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) return jsonDecode(body);
      return {"error": "Server error ${streamed.statusCode}: $body"};
    } catch (e) { return {"error": e.toString()}; }
  }

  // ── Web ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> predictBrainTumorWeb(
      Uint8List bytes, String filename) async {
    try {
      final safeName = _safeFilename(filename);
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/predict"));
      request.files.add(http.MultipartFile.fromBytes(
        'image', bytes,
        filename: safeName, contentType: _mimeFromName(safeName),
      ));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) return jsonDecode(body);
      return {"error": "Server error ${streamed.statusCode}: $body"};
    } catch (e) { return {"error": e.toString()}; }
  }

  // ── Parse probabilities ───────────────────────────────────
  // Training alphabetical order: glioma=0, meningioma=1, notumor=2, pituitary=3
  // Backend returns flat list: [p_glioma, p_meningioma, p_notumor, p_pituitary]
  static Map<String, double> parseProbabilities(dynamic allProbs) {
    List<double> probs;
    if (allProbs is List) {
      final raw = (allProbs.isNotEmpty && allProbs[0] is List)
          ? allProbs[0] as List        // unwrap nested [[...]]
          : allProbs;                  // already flat [...]
      probs = raw.map((e) => (e as num).toDouble()).toList();
    } else {
      probs = [0.0, 0.0, 0.0, 0.0];
    }

    // Keys MUST match CLASS_NAMES from training exactly
    return {
      'glioma':     probs.length > 0 ? probs[0] : 0.0,
      'meningioma': probs.length > 1 ? probs[1] : 0.0,
      'notumor':    probs.length > 2 ? probs[2] : 0.0,   // no underscore!
      'pituitary':  probs.length > 3 ? probs[3] : 0.0,
    };
  }
}
