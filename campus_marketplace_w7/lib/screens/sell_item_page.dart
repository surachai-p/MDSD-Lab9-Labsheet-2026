import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_vision_service.dart';

// --- นำเข้าไฟล์ที่จำเป็น ---
import '../repositories/listing_draft_repository.dart';
import '../models/listing_draft.dart';
// ------------------------------------

class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;

  const SellItemPage({super.key, required this.draftRepository});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _imageFile;
  bool _isAnalyzing = false;

  static const _prompt = '''วิเคราะห์ภาพสินค้านี้แล้วสร้างข้อมูลสำหรับลงขายสินค้า ประกอบด้วย 1. title (ชื่อสินค้าที่น่าสนใจ) 2. category (หมวดหมู่สินค้า) 3. description (รายละเอียดสินค้าแบบกระชับ น่าซื้อ)''';

  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างร่างประกาศ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _imageFile != null
                  ? Image.file(
                      _imageFile!,
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 250,
                      height: 250,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 10),

            _isAnalyzing
                ? const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text("AI กำลังวิเคราะห์ภาพสินค้า..."),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: _imageFile == null
                        ? null
                        : () async {
                            setState(() {
                              _isAnalyzing = true;
                            });

                            try {
                              final draft = await GeminiVisionService().analyzeProductImage(_imageFile!, prompt: _prompt);

                              setState(() {
                                _titleController.text = draft.title;
                                _categoryController.text = draft.category;
                                _descriptionController.text = draft.description;
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('AI วิเคราะห์สำเร็จ! กรุณาตรวจสอบข้อมูลก่อนยืนยัน')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                                );
                              }
                            } finally {
                              setState(() {
                                _isAnalyzing = false;
                              });
                            }
                          },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('ให้ AI ช่วยแนะนำ'),
                  ),

            const SizedBox(height: 30),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อประกาศ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'คำบรรยาย',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                if (_titleController.text.isEmpty || _imageFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณาระบุข้อมูลสินค้าและเลือกรูปภาพก่อนยืนยัน')),
                  );
                  return;
                }

                try {
                  final draftToSave = ListingDraft(
                    title: _titleController.text,
                    category: _categoryController.text,
                    description: _descriptionController.text,
                  );

                  // บันทึกโดยใช้ชื่อฟังก์ชันของคุณ
                  await widget.draftRepository.saveDraft(draftToSave, _imageFile!.path);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว')),
                    );
                    
                    // กลับไปหน้ารายการร่างทันทีหลังจากบันทึกเสร็จ
                    Navigator.pop(context); 
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'บันทึกร่างประกาศ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}