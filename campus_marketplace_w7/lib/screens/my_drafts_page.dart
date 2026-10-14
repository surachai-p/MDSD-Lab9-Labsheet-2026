import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/storage_service.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;
  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;
  int? _postingId; // id ของร่างที่กำลังโพสต์ (null = ไม่มี)

  @override
  void initState() {
    super.initState();
    _draftsFuture = widget.repository.getAllDrafts();
  }

  void _reload() {
    setState(() {
      _draftsFuture = widget.repository.getAllDrafts();
    });
  }

  Future<void> _deleteDraft(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.deleteDraft(id);
      if (!mounted) return;
      _reload();
      messenger.showSnackBar(
        const SnackBar(content: Text('ลบร่างประกาศเรียบร้อยแล้ว')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
    }
  }

  // Dialog ถามราคา (ร่างไม่มีราคาเก็บไว้) ต้องเป็นตัวเลขและมากกว่า 0
  Future<double?> _askPrice() {
    final ctrl = TextEditingController();
    String? error;
    return showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('ตั้งราคาสินค้า'),
          content: TextField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'ราคา (บาท)',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text.trim());
                if (v == null || v <= 0) {
                  setDialogState(() => error = 'กรุณากรอกตัวเลขที่มากกว่า 0');
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('ตกลง'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _postReal(ListingDraftRow draft) async {
    final messenger = ScaffoldMessenger.of(context);

    final price = await _askPrice();
    if (price == null) return;

    setState(() => _postingId = draft.id);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 1) อัปโหลดรูปก่อน แล้วรอ Download URL
      final imageUrl = await StorageService()
          .uploadListingImage(File(draft.imagePath), uid);

      // 2) สร้าง Item แล้วเขียนลง Firestore พร้อม URL
      final item = Item(
        id: 0, // ไม่ใช้ (Firestore สร้าง doc.id ให้เอง)
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: imageUrl,
        sellerId: uid,
      );
      await ItemRepositoryFirestore().postItem(item);

      // 3) ลบร่างออกจาก Local DB แล้ว Refresh (กันกดโพสต์ซ้ำ)
      await widget.repository.deleteDraft(draft.id);
      if (!mounted) return;
      _reload();
      messenger.showSnackBar(
        const SnackBar(content: Text('โพสต์ขายเรียบร้อยแล้ว')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('โพสต์ไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _postingId = null);
    }
  }

  String _formatDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
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
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final drafts = snapshot.data ?? [];
          if (drafts.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีร่างประกาศ ลองสร้างร่างที่ Tab ลงประกาศขายดูสิ'),
            );
          }
          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final isPosting = _postingId == draft.id;
              return ListTile(
                leading: SizedBox(
                  width: 56,
                  height: 56,
                  child: Image.file(
                    File(draft.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                title: Text(draft.title),
                subtitle: Text(
                  '${draft.category}\nแก้ไขล่าสุด ${_formatDateTime(draft.updatedAt)}',
                ),
                isThreeLine: true,
                trailing: isPosting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: _postingId != null
                                ? null
                                : () => _postReal(draft),
                            child: const Text('โพสต์ขายจริง'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'ลบร่าง',
                            onPressed: _postingId != null
                                ? null
                                : () => _deleteDraft(draft.id),
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
