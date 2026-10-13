import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    try {
      final fileName =
          'listings/${sellerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('ไม่สามารถอัปโหลดรูปภาพได้: $e');
    }
  }
}
