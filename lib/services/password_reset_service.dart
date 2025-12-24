import 'dart:convert';
import 'package:http/http.dart' as http;

class PasswordResetService {
  PasswordResetService._();

  // ✅ Your deployed HTTPS function URL:
  static const String _endpoint =
      'https://requestpasswordresetbynationalid-3qhjaabu4a-uc.a.run.app';

  static Future<void> requestByNationalId(String nationalId) async {
    final uri = Uri.parse(_endpoint);

    final resp = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'nationalId': nationalId.trim()}),
    );

    Map<String, dynamic> json;
    try {
      json =
          jsonDecode(resp.body.isEmpty ? '{}' : resp.body)
              as Map<String, dynamic>;
    } catch (_) {
      json = {};
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (json['ok'] == true) return;
      throw Exception(json['error'] ?? 'Unknown server response');
    } else {
      throw Exception(json['error'] ?? 'Server error (${resp.statusCode})');
    }
  }
}
