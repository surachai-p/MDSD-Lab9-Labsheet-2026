import 'dart:convert';
import 'package:flutter/material.dart';

/// แสดงรูปสินค้าได้ทั้ง URL ปกติ และ Base64 data URI
/// ถ้า [isStudentPost] เป็น true จะมีไอคอน 🎓 สีม่วงซ้อนที่มุมรูป
class ItemImage extends StatelessWidget {
  final String url;
  final double size;
  final bool isStudentPost;

  const ItemImage({
    super.key,
    required this.url,
    this.size = 56,
    this.isStudentPost = false,
  });

  Widget _buildImage() {
    const errorIcon = Icon(Icons.broken_image);

    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => errorIcon,
        );
      } catch (_) {
        return errorIcon;
      }
    }

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => errorIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: size, height: size, child: _buildImage()),
          ),
          if (isStudentPost)
            Positioned(
              right: -6,
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('🎓', style: TextStyle(fontSize: 11)),
              ),
            ),
        ],
      ),
    );
  }
}