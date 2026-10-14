import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiVisionService {
  static const _model = 'gemini-3.5-flash'; // ถ้าเจอ 404 เปลี่ยนเป็น gemini-3.8-flash
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<Map<String, dynamic>> analyzeProductImage(
      File imageFile, String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception('ไม่พบ GEMINI_API_KEY กรุณารันด้วย --dart-define');
    }

    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final mimeType =
        imageFile.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'category': {'type': 'STRING'},
            'description': {'type': 'STRING'},
          },
          'required': ['title', 'category', 'description'],
        },
      },
    });

    try {
      final response = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'}, body: requestBody)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 429) {
        throw Exception('ใช้งานเกินโควตาในขณะนี้ กรุณาลองใหม่');
      }
      if (response.statusCode != 200) {
        throw Exception(
            'เซิร์ฟเวอร์ Gemini ตอบกลับผิดพลาด (${response.statusCode})');
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception(
            'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น');
      }

      final finishReason = candidates.first['finishReason'] as String?;
      if (finishReason == 'SAFETY') {
        throw Exception(
            'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น');
      }

      final rawJsonText =
          candidates.first['content']['parts'][0]['text'] as String;
      try {
        final parsed = jsonDecode(rawJsonText) as Map<String, dynamic>;
        if (!parsed.containsKey('title') ||
            !parsed.containsKey('category') ||
            !parsed.containsKey('description')) {
          throw const FormatException('Field ไม่ครบ');
        }
        return parsed;
      } on FormatException {
        throw Exception('AI ตอบกลับมาในรูปแบบที่ไม่สมบูรณ์ กรุณาลองใหม่');
      }
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on SocketException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้');
    }
  }
}