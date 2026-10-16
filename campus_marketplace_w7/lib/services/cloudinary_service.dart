import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const String _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  Future<String> uploadListingImage(File imageFile) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw Exception(
        'ยังไม่ได้ตั้งค่า Cloudinary กรุณารันแอปด้วย '
        '--dart-define=CLOUDINARY_CLOUD_NAME=... และ '
        '--dart-define=CLOUDINARY_UPLOAD_PRESET=...',
      );
    }
    if (!await imageFile.exists()) {
      throw Exception('ไม่พบไฟล์รูปภาพในเครื่อง กรุณาเลือกรูปใหม่');
    }

    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$_cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw Exception(
        'อัปโหลดรูปไป Cloudinary ไม่สำเร็จ '
        '(HTTP ${streamedResponse.statusCode}): $responseBody',
      );
    }

    final responseData = jsonDecode(responseBody);
    if (responseData is! Map<String, dynamic> ||
        responseData['secure_url'] is! String ||
        (responseData['secure_url'] as String).isEmpty) {
      throw const FormatException('Cloudinary ไม่ได้ส่ง URL รูปภาพกลับมา');
    }

    return responseData['secure_url'] as String;
  }
}
