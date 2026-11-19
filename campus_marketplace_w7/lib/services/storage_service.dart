import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    try {
      final fileExtension = imageFile.path.contains('.')
          ? imageFile.path.split('.').last
          : 'jpg';
      final fileName =
          '${sellerId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final storageRef = _storage.ref().child('listings').child(fileName);

      // putFile ทำการอัปโหลดไฟล์ และ await จนกระทั่งเสร็จสิ้น
      final uploadTask = await storageRef.putFile(imageFile);

      // getDownloadURL หลังจาก putFile อัปโหลดเสร็จสมบูรณ์แล้วเท่านั้น
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('ไม่สามารถอัปโหลดรูปภาพได้: $e');
    }
  }
}
