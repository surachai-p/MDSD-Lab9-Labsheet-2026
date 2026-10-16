import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/cloudinary_service.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;
  final ItemRepositoryFirestore _firestoreRepository =
      ItemRepositoryFirestore();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _draftsFuture = widget.repository.getAllDrafts();
  }

  Future<void> _deleteDraft(ListingDraftRow draft) async {
    try {
      await widget.repository.deleteDraft(draft.id);
      if (!mounted) return;
      setState(() {
        _draftsFuture = widget.repository.getAllDrafts();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบร่าง "${draft.title}" แล้ว')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบร่างไม่สำเร็จ: $error')));
    }
  }

  Future<void> _publishDraft(ListingDraftRow draft) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนโพสต์ขาย')),
      );
      return;
    }

    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // 1. แสดง Dialog ถามราคาสินค้าก่อนเสมอ
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('ระบุราคาสำหรับ "${draft.title}"'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ราคาสินค้า (บาท)',
                suffixText: 'บาท',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาระบุราคา';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'กรุณากรอกตัวเลขที่มากกว่า 0';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('ยืนยันโพสต์ขาย'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final price = double.parse(priceController.text.trim());

    if (!mounted) return;

    // แสดง Progress Dialog ระหว่างอัปโหลด
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังอัปโหลดรูปและโพสต์ขายสินค้า...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final imageUrl = await _cloudinaryService.uploadListingImage(
        File(draft.imagePath),
      );

      final item = Item(
        id: DateTime.now().millisecondsSinceEpoch,
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: imageUrl,
        sellerId: user.uid,
      );

      await _firestoreRepository.postItem(item);

      // 4. ลบร่างออกจาก Local Database หลังโพสต์สำเร็จ
      await widget.repository.deleteDraft(draft.id);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // ปิด loading dialog

      setState(() {
        _draftsFuture = widget.repository.getAllDrafts();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('โพสต์ขาย "${draft.title}" สำเร็จแล้ว!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // ปิด loading dialog

      final errorString = error.toString().toLowerCase();
      final isOffline = errorString.contains('socketexception') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('network') ||
          errorString.contains('unavailable');

      final displayMessage = isOffline
          ? 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง'
          : 'โพสต์ขายไม่สำเร็จ: $error';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร่างประกาศของฉัน')),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('โหลดร่างประกาศไม่สำเร็จ: ${snapshot.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _draftsFuture = widget.repository.getAllDrafts();
                      });
                    },
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }

          final drafts = snapshot.data ?? [];
          if (drafts.isEmpty) {
            return const Center(child: Text('ยังไม่มีร่างประกาศ'));
          }

          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return ListTile(
                leading: _DraftImage(imagePath: draft.imagePath),
                title: Text(draft.title),
                subtitle: Text(
                  '${draft.category}\nแก้ไขล่าสุด ${_formatDateTime(draft.updatedAt)}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cloud_upload_outlined),
                      tooltip: 'โพสต์ขายจริง',
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () => _publishDraft(draft),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'ลบร่างประกาศ',
                      onPressed: () => _deleteDraft(draft),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DraftImage extends StatelessWidget {
  final String imagePath;

  const _DraftImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      return const SizedBox(
        width: 56,
        height: 56,
        child: Icon(Icons.image_not_supported_outlined),
      );
    }
    return Image.file(
      imageFile,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image),
    );
  }
}
