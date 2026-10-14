import 'dart:convert';
import 'dart:io';

class StorageService {
  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    final bytes = await imageFile.readAsBytes();
    final base64Str = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64Str';
  }
}