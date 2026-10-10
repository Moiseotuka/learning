import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/analyse_models.dart';

/// Service d'acces a l'API CitizenSynth (backend Python FastAPI).
///
/// Adresse par defaut : http://10.0.2.2:8000 (emulateur Android)
/// ou http://localhost:8000 (web / Windows).
class ApiService {
  static const String _defaultBase =
      String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:8000');

  final String baseUrl;
  final bool useLlm;

  ApiService({String? baseUrl, this.useLlm = true})
      : baseUrl = baseUrl ?? _defaultBase;

  Future<bool> healthCheck() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Analyse le corpus de demonstration.
  Future<AnalyseResult> analyserDemo() async {
    final resp = await http
        .post(Uri.parse('$baseUrl/analyser?use_llm=$useLlm'))
        .timeout(const Duration(minutes: 5));
    if (resp.statusCode != 200) {
      throw Exception('Erreur API ${resp.statusCode} : ${resp.body}');
    }
    return AnalyseResult.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)));
  }

  /// Analyse un fichier CSV local (ex. telecharge par l'utilisateur).
  Future<AnalyseResult> analyserFichier(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/analyser?use_llm=$useLlm'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send().timeout(const Duration(minutes: 5));
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      throw Exception('Erreur API ${resp.statusCode} : ${resp.body}');
    }
    return AnalyseResult.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)));
  }
}
