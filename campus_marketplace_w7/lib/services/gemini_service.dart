import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _model = 'gemini-3.5-flash'; // ถ้าเจอ 404 ให้เปลี่ยนตามรายชื่อล่าสุดที่เว็บ Google
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<String> generateText(String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception('ไม่พบ GEMINI_API_KEY กรุณารันด้วย --dart-define=GEMINI_API_KEY=your_key');
    }

    final uri = Uri.parse('$_baseUrl?key=$_apiKey');
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
    });

    try {
      final response = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'}, body: requestBody)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 429) {
        throw Exception('ใช้งานเกินโควตาที่กำหนดในขณะนี้ กรุณาลองใหม่ภายหลัง');
      }
      if (response.statusCode != 200) {
        throw Exception(
            'เซิร์ฟเวอร์ Gemini ตอบกลับผิดพลาด (รหัส ${response.statusCode})');
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini ไม่สามารถสร้างคำตอบได้ในครั้งนี้');
      }
      final parts = candidates.first['content']['parts'] as List<dynamic>;
      return parts.first['text'] as String;
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้');
    }
  }
}