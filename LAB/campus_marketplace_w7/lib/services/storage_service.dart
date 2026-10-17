import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    final fileName = '${sellerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = _storage.ref().child('listings/$fileName');
    final uploadTask = await storageRef.putFile(imageFile);
    return uploadTask.ref.getDownloadURL();
  }
}
