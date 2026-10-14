import 'dart:convert';
import 'package:flutter/material.dart';

class ItemImage extends StatelessWidget {
  final String url;
  final double size;

  const ItemImage({super.key, required this.url, this.size = 56});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('data:image')) {
      final bytes = base64Decode(url.split(',').last);
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: size),
      );
    }
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: size),
    );
  }
}