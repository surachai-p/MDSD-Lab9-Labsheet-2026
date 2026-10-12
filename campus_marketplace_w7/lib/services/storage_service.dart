import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// เวอร์ชันไม่ใช้ Firebase Storage: ย่อรูปแล้วแปลงเป็น Base64 data URI
class StorageService {
  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    final bytes = await imageFile.readAsBytes();

    // ย่อรูปใน isolate แยก ไม่ให้หน้าจอค้าง
    final jpgBytes = await compute(_resizeToJpg, bytes);

    if (jpgBytes.length > 700 * 1024) {
      throw Exception('รูปใหญ่เกินไปหลังย่อ กรุณาเลือกรูปอื่น');
    }

    return 'data:image/jpeg;base64,${base64Encode(jpgBytes)}';
  }
}

// ฟังก์ชันระดับบนสุด เพื่อให้ compute() เรียกใช้ได้
Uint8List _resizeToJpg(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('อ่านไฟล์รูปไม่ได้');
  }
  final resized =
      decoded.width > 600 ? img.copyResize(decoded, width: 600) : decoded;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
}