# บันทึกผลการทดลองสัปดาห์ที่ 9: Cloud Database — Firebase & Authentication
**ชื่อ-นามสกุล:** พรพรม สุขใจมิตร
**รหัสนักศึกษา:** 67030323

---

## ส่วนที่ 1: ตั้งค่า Firebase Project และเชื่อมกับ Flutter

### ✅ Checkpoint 1.1
**คำสั่ง:** ถ่ายภาพหน้าจอ Firebase Console ที่แสดงหน้า Project Overview ของโปรเจกต์ที่สร้างเสร็จแล้ว

> [!ภาพหน้าจอ Checkpoint 1.1]

![alt text](/img/image.png)

---

## ส่วนที่ 2: Firebase Authentication ด้วย Email และ Password

### ✅ Checkpoint 2.1
**คำสั่ง:** 
1. ภาพหน้าจอ Firebase Console เมนู Authentication → Users ที่แสดงบัญชีที่เพิ่งสมัคร
2. ภาพหน้าจอข้อความ Error สมัครซ้ำด้วย Email เดิม
3. ภาพหน้าจอข้อความ Error ใส่รหัสผ่านสั้นเกินไป
4. อธิบายว่าโค้ดส่วนใดใน `auth_service.dart` เป็นตัวจัดการแต่ละกรณี

> [!ภาพหน้าจอ Checkpoint 2.1 - บัญชีใน Console]

![alt text](/img/image-1.png)

> [!ภาพหน้าจอ Checkpoint 2.1 - Error Email ซ้ำ]

![alt text](/img/image-2.png)

> [!ภาพหน้าจอ Checkpoint 2.1 - Error รหัสผ่านสั้น]

![alt text](/img/image-3.png)

**คำอธิบายโค้ดจัดการ Error:**
การใช้ try/catch เพื่อดักจับ FirebaseAuthException แล้วส่งโค้ด error เข้าไปที่ฟังก์ชัน _translateErrorCode()

---

## ส่วนที่ 3: เข้าสู่ระบบด้วย Google Sign-In

### ✅ Checkpoint 3.1
**คำสั่ง:**
1. ภาพหน้าจอตอนเลือกบัญชี Google 
2. ภาพหน้าจอ Firebase Console ที่แสดงว่ามีผู้ใช้ใหม่ Provider เป็น Google เพิ่มเข้ามา
3. อธิบายว่า `idToken` กับ `accessToken` นำไปใช้ทำอะไรต่อ

> [!ภาพหน้าจอ Checkpoint 3.1 - เลือกบัญชี Google]

![alt text](/img/image-4.png)

> [!ภาพหน้าจอ Checkpoint 3.1 - Firebase Console User Google]

![alt text](/img/image-5.png)

อีเมลล์เดียกวันกับที่สมัครครับ

**คำอธิบายการใช้งาน idToken และ accessToken:**
ใช้เพื่อนำไปยืนยันกับ Firebase ว่า Google รับรองตัวตนผู้ใช้นี้แล้ว และขอสิทธิ์ในการอ่านข้อมูลพื้นฐานเช่น อีเมล  เพื่อสร้าง GoogleAuthProvider.credential

---

## ส่วนที่ 4: AuthGate — สลับหน้าจอตามสถานะผู้ใช้

### ✅ Checkpoint 4.1
**คำสั่ง:** 
1. ภาพหน้าจอแอปตอนเปิดครั้งแรก (ยังไม่ล็อกอิน)
2. ภาพหน้าจอหลังล็อกอินสำเร็จ (สลับมา MainScaffold อัตโนมัติ)
3. ภาพหน้าจอหลังกดออกจากระบบ (สลับกลับมา Login อัตโนมัติ)
4. อธิบายว่าทำไม `StreamBuilder` จึงทำให้ไม่ต้องเขียนโค้ด Navigate ไปมา

> [!ภาพหน้าจอ Checkpoint 4.1 - หน้าแรกก่อน Login]

![alt text](/img/image-6.png)

> [!ภาพหน้าจอ Checkpoint 4.1 - หน้า MainScaffold หลัง Login]

![alt text](/img/image-7.png)

> [!ภาพหน้าจอ Checkpoint 4.1 - หน้า Login หลัง Logout]

![alt text](/img/image-8.png)

**คำอธิบายการทำงานของ StreamBuilder:**
StreamBuilder จะคอย "ดักฟัง " การเปลี่ยนแปลงของ authStateChanges() อยู่ตลอดเวลา เมื่อสถานะผู้ใช้เปลี่ยน  ตัว StreamBuilder จะสั่ง Re-build ทันที ทำให้แอปสามารถตัดสินใจสลับ Widget  ไปมาได้เอง โดยที่เราไม่ต้องเขียนโค้ด Navigator.push() หรือ pop()

---

## ส่วนที่ 5: ขยาย Repository Pattern ด้วย ItemRepositoryFirestore

### 🧠 คำถามก่อนเขียนโค้ด (ขั้นตอนที่ 5.1)
**1. ทำไมเราจึง "เพิ่ม Implementation ใหม่" แทนที่จะแก้ไขของเดิม?**
เพื่อทำตามหลักการ Open-Closed Principle และการใช้ Repository Pattern ช่วยแยกโค้ดที่ติดต่อกับ UI ออกจากแหล่งข้อมูล ทำให้หน้า UI ไม่ต้องสนใจเลยว่าข้อมูลจะมาจาก API หรือ Firestore แค่เรียกเมธอดผ่าน Interface ก็พอ

**2. ถ้าอนาคตเปลี่ยน API ต้องแก้กี่ไฟล์?**
แก้เพียง 1 ไฟล์ คือไฟล์คลาส Implementation ของ Repository นั้นๆ

### ✅ Checkpoint 5.1
**คำสั่ง:** 
1. ภาพหน้าจอ Home ที่แสดงสินค้าจากทั้ง API และ Firestore ปนกัน พร้อม Badge
2. อธิบายข้อดีของการออกแบบให้ `HomePage` รู้จักแค่ Interface `ItemRepository`

> [!ภาพหน้าจอ Checkpoint 5.1 - หน้า Home แบบรวมข้อมูล]

![alt text](/img/image-9.png)

**คำอธิบายการออกแบบผ่าน Interface:**
การออกแบบให้หน้า HomePage เรียกใช้งานผ่าน Interface (ItemRepository) แทนที่จะเรียกใช้คลาส Implementation โดยตรง ช่วยแยกโค้ดส่วนแสดงผลออกจากส่วนการดึงข้อมูล หน้า HomePage จึงไม่จำเป็นต้องรับรู้ว่าเบื้องหลังข้อมูลถูกดึงมาจาก REST API หรือ Cloud Firestore หน้าที่ของมันมีแค่เรียกเมธอด getItems() ตามที่ Interface กำหนดไว้เท่านั้น

---

## ส่วนที่ 6: "โพสต์ขายจริง" — เชื่อม MyDraftsPage เข้ากับ Storage และ Firestore

### ✅ Checkpoint 6.1
**คำสั่ง:**
1. ภาพหน้าจอ Firebase Console (Firestore -> items) ที่มีเอกสารจริงและมี `sellerId`
2. ยืนยันว่าร่างรายการนั้นหายไปจาก MyDraftsPage

> [!ภาพหน้าจอ Checkpoint 6.1 - Firestore Documents]

![alt text](/img/image-10.png)

> [!ภาพหน้าจอ Checkpoint 6.1 - หน้า MyDraftsPage ที่ร่างหายไปแล้ว]

![alt text](/img/image-11.png)

### ✅ Checkpoint 6.2
**คำสั่ง:**
1. ภาพหน้าจอ Firebase Console (Storage) โชว์ไฟล์รูปภาพที่อัปโหลด
2. ภาพหน้าจอ Firestore โชว์ฟิลด์ `imageUrl`
3. ภาพหน้าจอแอปแสดงรูปนั้นบนหน้า Home 

> [!ภาพหน้าจอ Checkpoint 6.2 - Firebase Storage]
![alt text](/img/image-13.png)
ไม่มีบัตรครับ

> [!ภาพหน้าจอ Checkpoint 6.2 - Firestore imageUrl field]

![alt text](/img/image-12.png)

> [!ภาพหน้าจอ Checkpoint 6.2 - หน้า Home ที่โหลดรูปสำเร็จ]
เลยไม่มีรูปครับ

---

## ส่วนที่ 7: สำรวจ Firebase Security Rules (Self-Study)

### ✅ Checkpoint 7.1
**คำสั่ง:**
1. ภาพหน้าจอ Rules Playground กรณีผู้ใช้แก้ไขของตัวเอง (ผ่าน)
2. ภาพหน้าจอ Rules Playground กรณีผู้ใช้แก้ไขของคนอื่น (ถูกปฏิเสธ)
3. อธิบายว่าทำไม Client-side Validation อย่างเดียวจึงไม่ปลอดภัยพอ

> [!ภาพหน้าจอ Checkpoint 7.1 - Rules Playground (ผ่าน)]

![alt text](/img/image-14.png)

> [!ภาพหน้าจอ Checkpoint 7.1 - Rules Playground (ไม่ผ่าน)]

![alt text](/img/image-15.png)

**คำอธิบาย Client-side vs Server-side Security:**
เพราะ Client-side Validation เป็นเพียงการซ่อนปุ่ม หรือดักจับข้อมูลแค่ฝั่งหน้าตาแอป เท่านั้น ผู้ใช้ที่ไม่ประสงค์ดี สามารถเขียนโค้ด หรือใช้เครื่องมืออย่าง Postman ส่งคำสั่ง HTTP Request วิ่งตรงเข้าไปหาฐานข้อมูล Cloud Firestore ได้โดยไม่ต้องผ่านหน้าจอแอปพลิเคชันของเราเลย การตั้งค่า Firebase Security Rulesจึงเป็นปราการด่านสุดท้าย ในการป้องกัน

---

## ส่วนที่ 8: ทดสอบสถานการณ์ Offline และสถานะการล็อกอิน

### ✅ Checkpoint 8.1
**คำสั่ง:** ถ่ายภาพหน้าจอ 4 กรณี (เปิดใหม่ตอนล็อกอินค้าง, ปิดเน็ตดูรายการโปรด/ร่าง, ปิดเน็ตโพสต์ขาย, เปิดเน็ตโพสต์ขาย)

> [!ภาพหน้าจอ Checkpoint 8.1 - เปิดแอปใหม่โดยเข้าหน้า Home เลย]

![alt text](/img/image-16.png)

> [!ภาพหน้าจอ Checkpoint 8.1 - ปิดเน็ตดูรายการโปรด และ ร่าง]

![alt text](/img/image-17.png)

![alt text](/img/image-18.png)

> [!ภาพหน้าจอ Checkpoint 8.1 - ปิดเน็ตลองกดโพสต์ขาย (แสดง Error)]

![alt text](/img/image-19.png)

> [!ภาพหน้าจอ Checkpoint 8.1 - เปิดเน็ตกลับมา แล้วโพสต์ขายสำเร็จ]

![alt text](/img/image-20.png)
![alt text](/img/image-21.png)