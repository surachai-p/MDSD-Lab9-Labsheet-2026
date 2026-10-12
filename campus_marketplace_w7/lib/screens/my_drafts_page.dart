import 'dart:async';
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

  Future<void> _delete(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.deleteDraft(id);
      if (!mounted) return;
      _reload();
      messenger.showSnackBar(const SnackBar(content: Text('ลบร่างประกาศแล้ว')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
    }
  }

  // ตรวจว่ามีอินเทอร์เน็ตหรือไม่ (ไม่ต้องลง package เพิ่ม)
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('firebase.google.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Dialog ถามราคา (ร่างไม่มีราคาติดมา) ตรวจว่าเป็นตัวเลขและมากกว่า 0
  Future<double?> _askPrice() {
    final controller = TextEditingController();
    String? error;
    return showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ระบุราคาสินค้า'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'ราคา (บาท)',
              errorText: error,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final price = double.tryParse(controller.text.trim());
                if (price == null || price <= 0) {
                  setDialogState(() => error = 'กรุณากรอกตัวเลขที่มากกว่า 0');
                  return;
                }
                Navigator.pop(dialogContext, price);
              },
              child: const Text('โพสต์'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _postReal(ListingDraftRow d) async {
    final messenger = ScaffoldMessenger.of(context);

    final price = await _askPrice();
    if (price == null) return; // ผู้ใช้ยกเลิก

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนโพสต์')),
      );
      return;
    }

    // เช็คเครือข่ายก่อน ถ้าไม่มีให้แจ้งทันที ไม่หมุนค้าง
    if (!await _hasInternet()) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'เกิดข้อผิดพลาดในการโพสต์: ขาดการเชื่อมต่อเครือข่าย '
            'ไม่สามารถเข้าถึง Cloud Firestore (Offline)',
          ),
        ),
      );
      return;
    }

    setState(() {
      _postingId = d.id;
    });

    try {
      // 1) แปลงรูป (Base64) ให้เสร็จก่อน
      final imageUrl = await StorageService().uploadListingImage(
        File(d.imagePath),
        user.uid,
      );

      // 2) สร้าง Item แล้วเขียนลง Firestore พร้อมรูป (ใส่ timeout กันค้าง)
      final item = Item(
        id: DateTime.now().millisecondsSinceEpoch,
        title: d.title,
        price: price,
        description: d.description,
        category: d.category,
        imageUrl: imageUrl,
        sellerId: user.uid,
      );
      await ItemRepositoryFirestore()
          .postItem(item)
          .timeout(const Duration(seconds: 15));

      // 3) ลบร่างออกจาก Local Database กันโพสต์ซ้ำ
      await widget.repository.deleteDraft(d.id);

      if (!mounted) return;
      _reload();
      messenger.showSnackBar(
        SnackBar(content: Text('โพสต์ "${d.title}" เรียบร้อยแล้ว')),
      );
    } on TimeoutException {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'เกิดข้อผิดพลาดในการโพสต์: การเชื่อมต่อช้าหรือขัดข้อง '
            'ไม่สามารถเข้าถึง Cloud Firestore ได้ กรุณาลองใหม่',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('เกิดข้อผิดพลาดในการโพสต์ กรุณาลองใหม่อีกครั้ง'),
        ),
      );
      debugPrint('Post error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _postingId = null;
        });
      }
    }
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final isPosting = _postingId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ร่างประกาศของฉัน'),
        // แถบ Progress ระหว่างโพสต์
        bottom: isPosting
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
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
              child: Text('ยังไม่มีร่างประกาศ ลองสร้างที่แท็บ "ลงประกาศขาย" ดูสิ'),
            );
          }
          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final d = drafts[index];
              final thisPosting = _postingId == d.id;
              return ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.file(
                    File(d.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
                title: Text(d.title),
                subtitle: Text(
                    '${d.category}\nแก้ไขล่าสุด ${_formatDate(d.updatedAt)}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (thisPosting)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        tooltip: 'โพสต์ขายจริง',
                        icon: const Icon(Icons.cloud_upload),
                        onPressed: isPosting ? null : () => _postReal(d),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: isPosting ? null : () => _delete(d.id),
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