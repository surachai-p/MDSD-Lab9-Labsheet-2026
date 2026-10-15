# ใบงานปฏิบัติสัปดาห์ที่ 9 Cloud Database — Firebase & Authentication

**เครื่องมือ** Flutter, Firebase Console, FlutterFire CLI, Firebase Authentication, Cloud Firestore, Firebase Storage, google_sign_in

---

## วัตถุประสงค์การเรียนรู้

เมื่อทำใบงานนี้เสร็จสิ้น ผู้เรียนจะสามารถ

1. ตั้งค่า Firebase Project เพื่อเชื่อมต่อกับแอป Flutter ด้วย FlutterFire CLI
2. ใช้งาน Firebase Authentication เพื่อสมัครสมาชิกและเข้าสู่ระบบด้วย Email/Password และ Google Sign-In
3. ออกแบบหน้าจอที่สลับไปมาระหว่างสถานะ "ยังไม่ล็อกอิน" และ "ล็อกอินแล้ว" ด้วย `StreamBuilder` ฟัง Stream ของ Firebase Auth (`AuthGate`)
4. ขยาย Repository Pattern เดิมด้วยการเพิ่ม Implementation ใหม่ (`ItemRepositoryFirestore`) และรวมผลลัพธ์จากหลาย `ItemRepository` เข้าด้วยกันบนหน้า Home โดยไม่แก้ไข Interface เดิม
5. เขียน CRUD (Create, Read, Update, Delete) กับ Cloud Firestore ทั้งแบบอ่านครั้งเดียวและแบบฟังข้อมูล Real-time
6. อัปโหลดไฟล์รูปภาพขึ้น Firebase Storage และเชื่อมโยง URL ที่ได้เข้ากับเอกสารใน Firestore
7. อธิบายได้ว่าทำไม Client-side Validation อย่างเดียวไม่เพียงพอ และ Firebase Security Rules ทำหน้าที่อะไร

## สิ่งที่ต้องเตรียมก่อนเริ่ม

- โปรเจกต์ `campus_marketplace_w7` จากสัปดาห์ที่ 8 ที่มี `MainScaffold` 3 แท็บและ `MyDraftsPage` ทำงานได้ครบแล้ว
- บัญชี Google สำหรับสร้าง Firebase Project ฟรีที่ https://console.firebase.google.com (ใช้บัญชีเดียวกับที่สมัคร Google AI Studio ในสัปดาห์ที่ 7 ก็ได้)
- ติดตั้ง Node.js (เวอร์ชัน LTS ปัจจุบัน) เพื่อใช้คำสั่ง `npm install -g firebase-tools` และ `dart pub global activate flutterfire_cli`
- เครื่อง Android จริงหรือ Emulator ที่มีการตั้งค่า Google Play Services (จำเป็นสำหรับทดสอบ Google Sign-In) หรือ iOS Simulator/เครื่องจริงที่ล็อกอิน Apple ID ไว้แล้ว

> ⚠️ **ข้อควรรู้เรื่องความปลอดภัยของไฟล์ตั้งค่า Firebase**: ไฟล์ `google-services.json` (Android), `GoogleService-Info.plist` (iOS) และ `firebase_options.dart` ที่ได้จากคำสั่ง `flutterfire configure` **ไม่ใช่ความลับแบบเดียวกับ Gemini API Key** ในสัปดาห์ที่ 7 — Google ยืนยันว่าไฟล์เหล่านี้ฝังอยู่ในตัวแอปที่ปล่อยให้ผู้ใช้ดาวน์โหลดได้อย่างปลอดภัย เพราะเป็นเพียงตัวระบุโปรเจกต์ ไม่ใช่กุญแจเข้าถึงข้อมูล **ความปลอดภัยที่แท้จริงของ Firebase อยู่ที่ Security Rules**  ไม่ใช่การซ่อนไฟล์ตั้งค่าเหล่านี้ แต่ถึงอย่างนั้น ทีมพัฒนาส่วนใหญ่ก็ยังนิยม `.gitignore` ไฟล์เหล่านี้ไว้เพื่อป้องกันความสับสนเวลาสมาชิกในทีมใช้ Firebase Project คนละตัวกัน ให้ทำตามนี้ไว้เป็นนิสัยที่ดีเช่นกัน

---
## ขั้นตอนการทดลอง
## ส่วนที่ 1: ตั้งค่า Firebase Project และเชื่อมกับ Flutter

### ขั้นตอนที่ 1.1: 🔧 ทำตามขั้นตอน — สร้าง Firebase Project
**ให้ใช้ gmail account ส่วนตัวเพื่อไม่ใช่ account นักศึกษาของสถาบัน**
เปิด https://console.firebase.google.com กด **Create a new Firebase project** หรือ **Get stared by setting up a Firebase project** ตั้งชื่อโปรเจกต์ **ตั้งชื่อไม่ให้ชื่อซ้ำกับที่มีอยู่ใน Firebase**(เช่น `campus-marketplace-2026-<ชื่อนักศึกษาภาษาอังกฤษ>` ) ปิดการใช้งาน Google Analytics ได้หากไม่ต้องการ (ไม่จำเป็นสำหรับใบงานนี้) 


> ✅ **Checkpoint 1.1** ถ่ายภาพหน้าจอ Firebase Console ที่แสดงหน้า Project Overview ของโปรเจกต์ที่สร้างเสร็จแล้ว

``text

![alt text](image.png)
``

### ขั้นตอนที่ 1.2: 🔧 ทำตามขั้นตอน — ติดตั้งเครื่องมือและเชื่อมโปรเจกต์ด้วย FlutterFire CLI

ติดตั้งเครื่องมือที่จำเป็น (ทำครั้งเดียวต่อเครื่อง)

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

**กรณีใช้  Macbook แล้วติดปัญหาเรื่อง  Permission ให้ใช้คำสั่งดังนี้**
```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

จากนั้นเปิด Terminal ที่โฟลเดอร์ `campus_marketplace_w7` แล้วรัน

```bash
flutterfire configure
```
**หากเกิดปัญหา ระบบไม่รู้จักคำสั่ง flutterfire configure ให้รันคำสั่งส่วนนี้ก่อน**
```bash
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc
```

คำสั่งนี้จะให้เลือก Firebase Project ให้นักศึกษาพิมพ์ชื่อ Project ที่ได้สร้างไปในขั้นตอน 1.1
หลังจากนั้นเลือกแพลตฟอร์มที่ต้องการโดยกดลูกศรและ spacebar และเลือกเฉพาะ Android แพลตฟอร์ม (เพื่อไม่ให้เกิดปัญหา)   **แล้วกดปุ่ม Enter**
 เมื่อเสร็จแล้วจะได้ไฟล์ `lib/firebase_options.dart` ที่สร้างขึ้นอัตโนมัติ **ห้ามแก้ไขไฟล์นี้ด้วยมือ**

### ขั้นตอนที่ 1.3: 🔧 ทำตามขั้นตอน — เพิ่ม Dependencies และเริ่มต้น Firebase ในแอป

เพิ่มใน `pubspec.yaml`

```yaml
dependencies:
  firebase_core: ^4.14.0
  firebase_auth: ^6.6.0
  cloud_firestore: ^6.9.0
  firebase_storage: ^13.5.0
  google_sign_in: ^7.2.0
```

รัน `flutter pub get` แล้วแก้ไขจุดเริ่มต้นของแอป **`lib/main.dart`** ตามโครงสร้างในเนื้อหาสัปดาห์นี้หัวข้อ 9.1 — เพิ่มการเริ่มต้น Firebase ก่อนเรียก `runApp()` เท่านั้น ส่วนโค้ดเดิมจากสัปดาห์ที่ 8 (การสร้าง `AppDatabase`, `ChangeNotifierProvider<CartModel>`, คลาส `MyApp`) ยังอยู่ที่เดิมทุกจุด ไม่ต้องย้ายหรือลบ

ก่อนแก้ (`lib/main.dart`) 

```dart
void main() {
  final db = AppDatabase();
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: MyApp(database: db),
    ),
  );
}
```

**หลังแก้ (เพิ่ม import 2 บรรทัดต่อท้าย import เดิม และ เปลี่ยน void main() เป็น 3 บรรทัดใหม่)**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = AppDatabase();
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: MyApp(database: db),
    ),
  );
}
```

> 💡 สังเกตว่า `main()` เปลี่ยนจาก `void main()` เป็น `Future<void> main() async` เพราะ `Firebase.initializeApp()` เป็น Asynchronous ต้อง `await` ให้เสร็จก่อน `runApp()` เสมอ ส่วนคลาส `MyApp` ที่อยู่ด้านล่าง (ไฟล์เดียวกัน) ยังไม่ต้องแตะอะไรในขั้นตอนนี้ — การเชื่อม Firebase เข้ากับส่วนที่เหลือของแอปจะทำในส่วนที่ 4

---

## ส่วนที่ 2: Firebase Authentication ด้วย Email และ Password

### ขั้นตอนที่ 2.1: 🔧 ทำตามขั้นตอน — เปิดใช้งาน Sign-in Method ใน Console

(1) เข้าหน้าเว็บ Firebase Console ไปที่เมนู **Security ->Authentication**
(2) ถ้าเข้ามาครั้งแรก ให้เลือก  Get started แล้วเลือก **Sign-in method** เปิดใช้งาน **Email/Password** 
(3)เลือก add provider -> **Google** (จะใช้ Google ในส่วนที่ 3)
กำหนดค่า Public-facing name for project  เป็น campus-marketplace และเลือก Support email for project


### ขั้นตอนที่ 2.2: **สร้างไฟล์เอง** — AuthService

สร้างไฟล์ `lib/services/auth_service.dart` ตามโครงสร้างในเนื้อหาสัปดาห์นี้หัวข้อ 9.3

**ข้อกำหนดที่ต้องมีครบ (ตรวจสอบตก่อนไปต่อในขั้นตอนถัดไป):**

- มีเมธอด `Future<void> signUp({required String email, required String password})`
- มีเมธอด `Future<void> signIn({required String email, required String password})`
- มีเมธอด `Future<void> signOut()`
- ทุกเมธอดที่เรียก Firebase ต้อง `try/catch` ดักจับ `FirebaseAuthException` แล้วแปลแต่ละค่า `code` (เช่น `email-already-in-use`, `weak-password`, `invalid-credential`) ให้เป็นข้อความภาษาไทยที่ผู้ใช้เข้าใจได้ **ห้ามปล่อยให้ Error ดิบจาก Firebase หลุดไปแสดงตรง ๆ**


### ขั้นตอนที่ 2.3: **นักศึกษาเขียน Code เอง** — หน้าจอ Login / Sign Up

สร้างไฟล์ `lib/screens/login_page.dart` เป็นฟอร์มที่มีช่อง Email, Password และปุ่มสลับโหมด "เข้าสู่ระบบ" / "สมัครสมาชิก" เชื่อมกับ `AuthService` ที่สร้างไว้ แสดงสถานะ Loading ระหว่างรอ และแสดงข้อความ Error ที่แปลแล้วเมื่อล้มเหลว

> 🔧 **เชื่อม LoginPage เข้ากับแอปชั่วคราวเพื่อทดสอบ:** `AuthGate` ที่จะสลับหน้าจอ Login/Home ให้อัตโนมัติยังไม่ถูกสร้างจนกว่าจะถึงส่วนที่ 4 ดังนั้นตอนนี้ `LoginPage` ที่เพิ่งสร้างยังไม่มีจุดไหนในแอปเรียกใช้เลย ให้แก้ `lib/main.dart` ในเมธอด `MyApp.build()` ชั่วคราวก่อน เปลี่ยนจาก `home: MainScaffold(...)` เป็น `home: const LoginPage()` เพื่อให้รันแอปแล้วเห็นหน้า Login ทันทีและทดสอบ Checkpoint 2.1 กับ Checkpoint 3.1 (ส่วนที่ 3) ได้จริง เมื่อทดสอบทั้งสอง Checkpoint เสร็จแล้ว **ให้เปลี่ยน `home:` กลับเป็น `MainScaffold(...)` เหมือนเดิมก่อนเริ่มส่วนที่ 4** เพราะส่วนที่ 4 จะสร้าง `AuthGate` มาแทนที่บรรทัดนี้แบบถาวร ไม่ต้องสลับไปมาด้วยมืออีกต่อไปหลังจากนั้น

> ✅ **Checkpoint 2.1** ทดสอบสมัครสมาชิกด้วย Email ใหม่สำเร็จ ถ่ายภาพหน้าจอ Firebase Console เมนู Authentication → Users ที่แสดงบัญชีที่เพิ่งสมัคร จากนั้นทดสอบกรณีผิดพลาด 2 กรณี คือ (ก) สมัครซ้ำด้วย Email เดิม และ (ข) ใส่รหัสผ่านสั้นเกินไป ถ่ายภาพหน้าจอข้อความ Error ทั้งสองกรณี พร้อมอธิบายว่าโค้ดส่วนใดใน `auth_service.dart` เป็นตัวจัดการแต่ละกรณี

``text
![alt text](image-1.png).
"ในกรณีสมัครเเล้วมีบัญชีซ้ำ"
![alt text](image-2.png)
"ในกรณีสมัครบัญชีปกติสำเร็จ"
![alt text](image-3.png)
"ในกรณีที่สมัครแล้วรหัสสั้นเกินไป"

``

---

## ส่วนที่ 3: เข้าสู่ระบบด้วย Google Sign-In

### ขั้นตอนที่ 3.1: 🔧 ทำตามขั้นตอน — ตั้งค่า SHA-1 (Android)

Google Sign-In บน Android ต้องลงทะเบียน SHA-1 Fingerprint ของเครื่องที่ใช้ Debug ไว้ใน Firebase Console หา SHA-1 ด้วยคำสั่ง

```bash
cd android && ./gradlew signingReport
```

คัดลอกค่า SHA-1 ที่อยู่ใต้ `Variant: debug` ไปวางใน Firebase Console → Project Settings → เลือกแอป Android → Add fingerprint จากนั้นดาวน์โหลดไฟล์ `google-services.json` ใหม่มาทับไฟล์เดิมในโฟลเดอร์ `android/app/`

### ขั้นตอนที่ 3.2: **นักศึกษาเขียน Code เอง** — signInWithGoogle()

เพิ่มเมธอด `signInWithGoogle()` ใน `AuthService` ตามโครงสร้างสมบูรณ์ในเนื้อหาสัปดาห์นี้หัวข้อ 9.4 (เรียก `GoogleSignIn.instance.initialize()`, `authenticate()`, ดึง `idToken` จาก `googleUser.authentication.idToken` และ `accessToken` จาก `authorizationClient.authorizationForScopes()` แล้วประกอบเป็น `GoogleAuthProvider.credential()` ก่อนส่งให้ `FirebaseAuth.instance.signInWithCredential()`)

### ขั้นตอนที่ 3.3: 🔧 ทำตามขั้นตอน — เพิ่มปุ่ม "เข้าสู่ระบบด้วย Google" ในหน้า Login

> ✅ **Checkpoint 3.1** ทดสอบกดปุ่มเข้าสู่ระบบด้วย Google ด้วยบัญชี Google จริงของคุณ ถ่ายภาพหน้าจอตอนเลือกบัญชี Google และภาพหน้าจอ Firebase Console ที่แสดงว่ามีผู้ใช้ใหม่ Provider เป็น Google เพิ่มเข้ามา อธิบายว่า `idToken` กับ `accessToken` ที่ได้จาก Google นำไปใช้ทำอะไรต่อในขั้นตอนการยืนยันตัวตนกับ Firebase (อ้างอิงหัวข้อ 9.4)

``text
![alt text](image-4.png)
![alt text](image-5.png)
"idToken คือ JWT ที่ Google ลงลายเซ็นไว้ มีข้อมูลตัวตนของผู้ใช้ (อีเมล ชื่อ user ID) Firebase ใช้ตรวจสอบว่าผู้ใช้คือใครจริง จึงเป็นตัวหลักในการยืนยันตัวตน

accessToken คือโทเค็นสำหรับเข้าถึงบริการของ Google ตามสิทธิ์ (scope) ที่ผู้ใช้อนุญาต เช่น email, profile Firebase รับไปเป็นข้อมูลประกอบใน credential"

``

---

## ส่วนที่ 4: AuthGate — สลับหน้าจอตามสถานะผู้ใช้

### ขั้นตอนที่ 4.1: 🧠 คิดเอง (มีโครงให้) — สร้าง AuthGate Widget

สร้างไฟล์ `lib/screens/auth_gate.dart` เป็น `StreamBuilder<User?>` ที่ฟัง `FirebaseAuth.instance.authStateChanges()` ตามโครงสร้างในหัวข้อ 9.4 ใช้ Pseudocode นี้เป็นโครง แล้วเติมโค้ดจริงเอง:

```
class AuthGate extends StatelessWidget:
    รับพารามิเตอร์: itemRepositories (List<ItemRepository>), favoritesRepository, draftRepository

    build(context):
        return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot):
                ถ้า snapshot ยังไม่มีข้อมูล (connectionState == waiting):
                    แสดง CircularProgressIndicator กลางจอ

                ถ้า snapshot.data เป็น null (ยังไม่ล็อกอิน):
                    แสดง LoginPage()

                ถ้า snapshot.data เป็น User จริง (ล็อกอินแล้ว):
                    แสดง MainScaffold(
                        itemRepositories: itemRepositories,
                        favoritesRepository: favoritesRepository,
                        draftRepository: draftRepository,
                    )
        )
```

จากนั้นแก้ `lib/main.dart` ในเมธอด `MyApp.build(context)` ให้เรียก `AuthGate` แทนที่จะเรียก `MainScaffold` ตรง ๆ (ตัวแปร `database` ที่รับมาจาก Constructor ของ `MyApp` ตั้งแต่สัปดาห์ที่ 8 ยังใช้ตัวเดิม ไม่ต้องสร้างใหม่หรือย้ายที่):

ก่อนแก้ (`lib/main.dart` — ภายใน `MyApp.build()`)

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Campus Marketplace',
    debugShowCheckedModeBanner: false,
    home: MainScaffold(
      itemRepository: ItemRepositoryApi(),
      favoritesRepository: FavoritesRepositoryDrift(database),
      draftRepository: ListingDraftRepositoryDrift(database),
    ),
  );
}
```

หลังแก้

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Campus Marketplace',
    debugShowCheckedModeBanner: false,
    home: AuthGate(
      itemRepositories: [ItemRepositoryApi(), ItemRepositoryFirestore()],
      favoritesRepository: FavoritesRepositoryDrift(database),
      draftRepository: ListingDraftRepositoryDrift(database),
    ),
  );
}
```

> ⚠️ สังเกตว่า `itemRepository` (ตัวเดียว) ใน `MainScaffold` จะต้องถูกเปลี่ยนเป็น `itemRepositories` (List) ด้วย เพราะตอนนี้มีสองแหล่งข้อมูลสินค้าแล้ว — รายละเอียดการแก้ `MainScaffold` และ `HomePage` ให้รองรับ List นี้อยู่ในส่วนที่ 5 อย่าเพิ่งแก้ตรงนี้จนกว่าจะเขียน `ItemRepositoryFirestore` เสร็จ

### ขั้นตอนที่ 4.2: 🔧 ทำตามขั้นตอน — เพิ่มปุ่มออกจากระบบ

เพิ่มปุ่ม "ออกจากระบบ" ใน AppBar ของ `HomePage` ที่เรียก `AuthService().signOut()`

> ✅ **Checkpoint 4.1** ถ่ายภาพหน้าจอ 3 ภาพเรียงกัน คือ (ก) แอปตอนเพิ่งเปิดขึ้นมาครั้งแรกแบบยังไม่ล็อกอิน แสดงหน้า Login (ข) หลังล็อกอินสำเร็จ แอปสลับไปแสดง `MainScaffold` อัตโนมัติโดยไม่ต้องกดอะไรเพิ่ม และ (ค) หลังกด "ออกจากระบบ" แอปสลับกลับไปหน้า Login เอง อธิบายว่าทำไมการใช้ `StreamBuilder` ฟัง `authStateChanges()` จึงทำให้ไม่ต้องเขียนโค้ดสั่ง Navigate ไปมาด้วยมือเลย

``text
![alt text](image-6.png)
![alt text](image-7.png)
![alt text](image-8.png)
"แอปมี "ตัวคอยเฝ้า" สถานะล็อกอินของ Firebase อยู่ตลอด พอเราล็อกอินหรือออกจากระบบ ตัวเฝ้าจะแจ้งมาเองว่าตอนนี้มีคนล็อกอินอยู่ไหม แล้ว AuthGate ก็เลือกหน้าตามนั้น ถ้าไม่มีคนล็อกอินก็โชว์หน้า Login ถ้ามีก็โชว์หน้าหลัก เลยไม่ต้องเขียนโค้ดสั่งเปลี่ยนหน้าเองเลย หน้าจอเปลี่ยนตามสถานะล็อกอินให้อัตโนมัติ"
```

---

## ส่วนที่ 5: ขยาย Repository Pattern ด้วย ItemRepositoryFirestore

### ขั้นตอนที่ 5.1: 🧠 คิดเอง

ก่อนเขียนโค้ด ให้ตอบคำถามต่อไปนี้ (อ้างอิง `campus_marketplace_lab_roadmap.md` ข้อ 5.6 และเนื้อหาหัวข้อ 9.5):

1. ทำไมเราจึง "เพิ่ม Implementation ใหม่" (`ItemRepositoryFirestore`) แทนที่จะแก้ไข `ItemRepositoryApi` เดิม หรือเขียนโค้ดเรียก Firestore ตรงจาก `HomePage`?

2. ถ้าในอนาคตอาจารย์สั่งให้เปลี่ยนจาก Fake Store API ไปใช้ API อื่น ต้องแก้ไฟล์กี่ไฟล์ ถ้าทุก Widget เรียกผ่าน Interface `ItemRepository` เท่านั้น?

```text
1. เพราะ ItemRepositoryApi ใช้ดึงข้อมูลจาก Fake Store API อยู่แล้ว การแยก ItemRepositoryFirestore ออกมาใหม่ช่วยให้แต่ละคลาสทำหน้าที่ของตัวเอง และไม่กระทบโค้ดเดิม ส่วนการเรียก Firestore จาก HomePage โดยตรงจะทำให้หน้าจอผูกติดกับแหล่งข้อมูลและทดสอบได้ยาก ดังนั้นการใช้ ItemRepositoryFirestore ที่ implements ItemRepository จึงช่วยให้เปลี่ยนแหล่งข้อมูลได้โดยไม่ต้องแก้โค้ดหน้าจอ
2. โดยทั่วไปแก้ 1 ไฟล์ คือ Implementation ที่ใช้เชื่อมต่อ API หากต้องสลับไปใช้ Implementation ใหม่ ก็แก้จุดสร้างออบเจกต์ใน main.dart อีก 1 จุด โดย Widget ต่าง ๆ ไม่ต้องแก้ เพราะเรียกใช้งานผ่าน Interface ItemRepository อยู่แล้ว
```

### ขั้นตอนที่ 5.2: **นักศึกษาเขียน Code เอง** — ItemRepositoryFirestore

สร้างไฟล์ `lib/repositories/item_repository_firestore.dart` ตามโครงสร้างในเนื้อหาสัปดาห์นี้หัวข้อ 9.5-9.6

**ข้อกำหนดที่ต้องมีครบ (ตรวจสอบตัวเองก่อนไปต่อ):**

- `class ItemRepositoryFirestore implements ItemRepository` — Interface เดิมจากสัปดาห์ที่ 6 **ห้ามแก้ไข**
- `Future<List<Item>> getItems()` อ่านทุกเอกสารใน Collection `items` ครั้งเดียวด้วย `.get()` แล้วแปลงเป็น `List<Item>` (ทำให้ `HomePage` เรียกใช้งานได้เหมือน `ItemRepositoryApi` ทุกประการโดยไม่ต้องรู้ว่าเบื้องหลังเป็น Firestore)
- `Future<void> postItem(Item item)` เขียนเอกสารใหม่ลง Collection `items`
- `Stream<List<Item>> watchMyListings(String sellerId)` ใช้ `.snapshots()` ฟังเฉพาะเอกสารที่ `sellerId` ตรงกับพารามิเตอร์ แบบ Real-time (ไม่ใช่ `.get()` ครั้งเดียว)

### ขั้นตอนที่ 5.3: 🔧 ทำตามขั้นตอน — รวมสินค้าจาก API และ Firestore บนหน้า Home

แก้ `MainScaffold` และ `HomePage` ให้รับ `List<ItemRepository>` แทนตัวเดียว ตามนี้

ก่อนแก้ (`main_scaffold.dart`)

```dart
class MainScaffold extends StatefulWidget {
  final ItemRepository itemRepository;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;
  const MainScaffold({
    super.key,
    required this.itemRepository,
    required this.favoritesRepository,
    required this.draftRepository,
  });
  ...
}

// ใน build():
final pages = [
  HomePage(repository: widget.itemRepository, favoritesRepository: widget.favoritesRepository),
  SellItemPage(draftRepository: widget.draftRepository),
  FavoritesPage(repository: widget.favoritesRepository),
];
```

หลังแก้

```dart
class MainScaffold extends StatefulWidget {
  final List<ItemRepository> itemRepositories;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;
  const MainScaffold({
    super.key,
    required this.itemRepositories,
    required this.favoritesRepository,
    required this.draftRepository,
  });
  ...
}

// ใน build():
final pages = [
  HomePage(repositories: widget.itemRepositories, favoritesRepository: widget.favoritesRepository),
  SellItemPage(draftRepository: widget.draftRepository),
  FavoritesPage(repository: widget.favoritesRepository),
];
```

และแก้ `HomePage` ให้เรียก `getItems()` จากทุก Repository ใน List พร้อมกันด้วย `Future.wait(...)` แล้วรวมผลลัพธ์เป็น List เดียวก่อนส่งให้ `ListView.builder` ใส่ Badge หรือไอคอนเล็ก ๆ บน `ItemCard` เพื่อบอกผู้ใช้ว่าแต่ละรายการมาจากแหล่งใด (เช่น 🏪 = จาก API, 🎓 = โพสต์จริงโดยนักศึกษา)

> ✅ **Checkpoint 5.1** ถ่ายภาพหน้าจอ Home ที่แสดงสินค้าจากทั้งสองแหล่งข้อมูลปนกันอยู่ในลิสต์เดียว พร้อม Badge ที่แยกแหล่งที่มาชัดเจน (ถ้ายังไม่เคยมีประกาศจริงใน Firestore เลย ให้ทำส่วนที่ 6 ให้เสร็จก่อนแล้วย้อนกลับมาถ่ายภาพ Checkpoint นี้) อธิบายว่าการออกแบบให้ `HomePage` ไม่รู้จัก `ItemRepositoryApi`/`ItemRepositoryFirestore` โดยตรง แต่รู้จักผ่าน Interface `ItemRepository` เท่านั้น ช่วยให้ทดสอบหรือเปลี่ยนแหล่งข้อมูลในอนาคตง่ายขึ้นอย่างไร

``text
![alt text](image-9.png)
"HomePage รู้จักแค่ Interface ItemRepository จึงเปลี่ยนแหล่งข้อมูลได้โดยไม่ต้องแก้โค้ดหน้าจอ และทดสอบได้ง่ายโดยใช้ Repository จำลองแทน API หรือ Firebase จริง"
```

---

## ส่วนที่ 6: "โพสต์ขายจริง" — เชื่อม MyDraftsPage เข้ากับ Storage และ Firestore

### ขั้นตอนที่ 6.1: **นักศึกษาเขียน Code เอง** — StorageService

สร้างไฟล์ `lib/services/storage_service.dart` ตามโครงสร้างในหัวข้อ 9.7-9.8

**ข้อกำหนดที่ต้องมีครบ (ตรวจสอบตัวเองก่อนไปต่อ):**

- มีเมธอด `Future<String> uploadListingImage(File imageFile, String sellerId)` คืนค่าเป็น Download URL
- ตั้งชื่อไฟล์บน Storage ให้ไม่ซ้ำกัน (เช่น ใช้ `sellerId` ผสมกับ `DateTime.now().millisecondsSinceEpoch`) ไม่ใช่ใช้ชื่อไฟล์เดิมจากเครื่องผู้ใช้ตรง ๆ
- เรียก `getDownloadURL()` **หลังจาก** `putFile()` อัปโหลดเสร็จสมบูรณ์แล้วเท่านั้น (ต้อง `await` ให้ถูกจุด)

### ขั้นตอนที่ 6.2: 🧠 คิดเอง (มีโครงให้) — เพิ่ม sellerId ให้ Item และแปลงเป็น Firestore ได้

`ListingDraft` จากสัปดาห์ที่ 7 (`title`, `category`, `description`) และตาราง `ListingDrafts` จากสัปดาห์ที่ 8 (`title`, `category`, `description`, `imagePath`) **ไม่มี field ราคาเลย** ส่วนคลาส `Item` ก็ยังไม่มี `sellerId` ใช้ Pseudocode นี้เป็นโครงในการแก้ไข:

```
แก้ไข class Item (lib/models/item.dart):
    เพิ่ม field ใหม่: final String? sellerId   // nullable เพราะสินค้าจาก Fake Store API ไม่มี sellerId

    เพิ่มเมธอด toFirestore() -> Map<String, dynamic>:
        คืนค่า Map ที่มี key ตรงกับชื่อ field ทั้งหมด (title, price, description, category, imageUrl, sellerId)

    เพิ่ม factory Item.fromFirestore(DocumentSnapshot doc):
        อ่านค่าจาก doc.data() เป็น Map แล้วสร้าง Item กลับมา
        ใส่ doc.id เป็น id ของ Item ด้วย (ต่างจาก fromJson ของสัปดาห์ที่ 7 ที่ไม่มี id จาก API)
```

> 💡 เพราะร่างประกาศ (`ListingDraftRow`) ไม่มีราคาเก็บไว้ ตอนกด "โพสต์ขายจริง" ในขั้นตอนถัดไปจึงต้อง**ถามราคาจากผู้ใช้ก่อนเสมอ** ด้วย Dialog — ไม่ใช่ดึงราคาจากร่างโดยตรงเพราะไม่มีให้ดึง

### ขั้นตอนที่ 6.3: **นักศึกษาเขียน Code เอง** — ปุ่ม "โพสต์ขายจริง" ใน MyDraftsPage

เพิ่มปุ่ม "โพสต์ขายจริง" ใน `ListTile` ของแต่ละร่างในหน้า `MyDraftsPage` (จากสัปดาห์ที่ 8) ที่ทำตามลำดับนี้เมื่อกด

**ข้อกำหนดที่ต้องมีครบ (ตรวจสอบตัวเองก่อนไปต่อ):**

- แสดง Dialog ถามราคาสินค้าก่อนเสมอ (เพราะร่างไม่มีราคาติดมา) ตรวจสอบว่ากรอกเป็นตัวเลขและมากกว่า 0
- อัปโหลดรูปจาก `draft.imagePath` ขึ้น Storage ผ่าน `StorageService().uploadListingImage(...)` **ก่อน** รอรับ Download URL แล้วค่อยเขียนเอกสารลง Firestore พร้อม URL นั้น (ห้ามสลับลำดับ เพราะ Firestore ต้องมี URL ที่ใช้งานได้จริงตั้งแต่ตอนสร้างเอกสาร)
- สร้าง `Item` จากข้อมูลร่าง + ราคาที่กรอก + `sellerId: FirebaseAuth.instance.currentUser!.uid` แล้วเรียก `ItemRepositoryFirestore().postItem(item)`
- หลังโพสต์สำเร็จ เรียก `draftRepository.deleteDraft(draft.id)` ลบร่างออกจาก Local Database แล้ว Refresh รายการร่างบนหน้าจอ (ป้องกันไม่ให้กดโพสต์ซ้ำร่างเดิมสองครั้ง) และแสดง SnackBar ยืนยัน
- ระหว่างอัปโหลดให้แสดง Progress Indicator ตามที่อธิบายไว้ในหัวข้อ 9.7

> ✅ **Checkpoint 6.1** โพสต์ขายจริงอย่างน้อย 2 รายการผ่านแอป ถ่ายภาพหน้าจอ Firebase Console เมนู Firestore Database ที่แสดง Collection `items` มีเอกสารที่โพสต์เข้ามาจริง พร้อม field `sellerId` ที่ตรงกับ `uid` ของบัญชีที่ใช้ทดสอบ และยืนยันว่าร่างทั้งสองรายการหายไปจาก `MyDraftsPage` แล้ว

`` text
```

> ✅ **Checkpoint 6.2** ถ่ายภาพหน้าจอ Firebase Console เมนู Storage ที่แสดงไฟล์รูปภาพที่อัปโหลดสำเร็จ และภาพหน้าจอ Firestore ที่แสดงว่าเอกสารมี field `imageUrl` เป็น URL จริงที่เปิดดูได้ ถ่ายภาพหน้าจอแอปที่แสดงรูปสินค้านั้นบนหน้า Home ผ่าน `Image.network(imageUrl)` ด้วย (ย้อนกลับไปถ่ายภาพ Checkpoint 5.1 ให้ครบตอนนี้ ถ้ายังไม่ได้ทำ)

```text
บันทึกรูปผลลัพธ์ที่นี่
```

---

## ส่วนที่ 7 (Self-Study): สำรวจ Firebase Security Rules

ส่วนนี้เป็นการศึกษาด้วยตนเองเพิ่มเติมจากที่กล่าวถึงสั้น ๆ ในเนื้อหาหัวข้อ 9.9 ไม่ใช่แกนหลักของใบงาน แต่**สำคัญมากสำหรับการทำแอปจริง**เพราะโค้ด Flutter ทั้งหมดที่เขียนมาในส่วนที่ 1-6 ยังไม่ได้ป้องกันไม่ให้ผู้ใช้คนหนึ่งแก้ไข/ลบประกาศของอีกคนหนึ่งเลย (เพียงแค่ UI ไม่มีปุ่มให้กดเท่านั้น ผู้ที่เขียนโค้ดเรียก Firestore เองโดยตรงยังทำได้อยู่)

### ขั้นตอนที่ 7.1: 🔧 ทำตามขั้นตอน — ทดลองแก้ Rules เบื้องต้น

ใน Firebase Console ไปที่ Firestore Database → Rules แก้ไข Rules ของ Collection `items` ให้เป็น

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /items/{itemId} {
      allow read: if true;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.sellerId;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.sellerId;
    }
  }
}
```

กด **Publish** แล้วใช้แท็บ **Rules Playground** ในหน้าเดียวกันทดลองจำลอง 2 กรณี คือ (ก) ผู้ใช้ที่ล็อกอินพยายามแก้ไขเอกสารที่ตัวเอง `sellerId` ตรงกัน (ควรผ่าน) และ (ข) ผู้ใช้คนเดียวกันพยายามแก้ไขเอกสารของคนอื่น (ควรถูกปฏิเสธ)

> ⚠️ ถ้า Checkpoint 6.1 ยังไม่เคยโพสต์ผ่านมาก่อนเลย ให้ Publish Rules นี้ **หลังจาก** โพสต์ขายจริงสำเร็จไปแล้วอย่างน้อย 1 รายการ เพราะ Rules ชุดนี้บังคับว่าต้องมี `sellerId` ตรงกับผู้เขียนเสมอ ถ้าโค้ดในส่วนที่ 6 ยังไม่แนบ `sellerId` ให้ถูกต้อง การโพสต์ครั้งต่อไปจะล้มเหลวด้วย `permission-denied` ทันที

> ✅ **Checkpoint 7.1 (Self-Study)** ถ่ายภาพหน้าจอผลการทดลองทั้ง 2 กรณีใน Rules Playground เขียนอธิบายสั้น ๆ ว่าทำไม Client-side Validation (การไม่แสดงปุ่มแก้ไขให้เห็น) เพียงอย่างเดียวจึงไม่เพียงพอต่อความปลอดภัยของข้อมูลจริง

```text
บันทึกรูปผลลัพธ์ที่นี่ และคำอธิบาย
```

---

## ส่วนที่ 8: ทดสอบสถานการณ์ Offline และสถานะการล็อกอิน

### ขั้นตอนที่ 8.1: 🔧 ทำตามขั้นตอน

ทดสอบทีละกรณีต่อไปนี้

1. ล็อกอินค้างไว้ แล้วปิดแอปทิ้งไปทั้งหมด (ไม่ใช่แค่ย่อ) จากนั้นเปิดแอปใหม่อีกครั้ง — ควรเข้าหน้า `MainScaffold` ทันทีโดยไม่ต้องล็อกอินซ้ำ (Firebase Auth จำสถานะล็อกอินไว้ให้อัตโนมัติ)
2. ปิด WiFi/Data ของเครื่องให้หมด แล้วลองเปิดแท็บ "รายการโปรด" และ "ร่างของฉัน" — ควรยังใช้งานได้ปกติเพราะเก็บอยู่ใน Local Database (Drift) ไม่ต้องพึ่งเครือข่าย
3. ขณะยังปิดเครือข่ายอยู่ ลองกด "โพสต์ขายจริง" กับร่างสักชิ้น — ควรเกิด Error เพราะ Firestore/Storage ต้องการเครือข่ายเสมอ (ต่างจาก Local Database) ตรวจสอบว่าแอปแสดงข้อความ Error ที่เข้าใจได้ ไม่ Crash
4. เปิดเครือข่ายกลับมา แล้วลองกด "โพสต์ขายจริง" รายการเดิมอีกครั้ง — ควรสำเร็จตามปกติ

> ✅ **Checkpoint 8.1** ถ่ายภาพหน้าจอผลการทดสอบทั้ง 4 ข้อ อธิบายว่าทำไมฟีเจอร์ที่พึ่งพา Local Database (Favorites, ร่างประกาศ) กับฟีเจอร์ที่พึ่งพา Firebase (โพสต์ขายจริง, ดูสินค้าจาก Firestore) จึงมีพฤติกรรมตอนออฟไลน์ต่างกัน

```text
บันทึกรูปผลลัพธ์ที่นี่ และคำอธิบาย
```

---

## ปัญหาที่พบบ่อยและวิธีแก้ไข (Troubleshooting)

**Error `[core/no-app]` หรือ `Firebase has not been correctly initialized`** มักเกิดจากลืมเรียก `await Firebase.initializeApp(...)` ก่อน `runApp()` หรือลืม `WidgetsFlutterBinding.ensureInitialized()` ที่บรรทัดแรกสุดของ `main()` ตรวจสอบลำดับโค้ดในขั้นตอน 1.3 อีกครั้ง

**Google Sign-In ขึ้น Error `ApiException: 10` บน Android** เกือบทุกครั้งเกิดจากยังไม่ได้เพิ่ม SHA-1 Fingerprint ใน Firebase Console หรือเพิ่มแล้วแต่ยังไม่ได้ดาวน์โหลด `google-services.json` ใหม่มาทับไฟล์เดิม ให้ทำซ้ำขั้นตอนที่ 3.1 อย่างครบถ้วน และรัน `flutter clean` ก่อนรันแอปใหม่

**เข้าสู่ระบบด้วย Google สำเร็จ แต่ `FirebaseAuth.instance.signInWithCredential()` โยน Error `invalid-credential`** ตรวจสอบว่าเปิดใช้งาน Google เป็น Sign-in Method ใน Firebase Console แล้วจริง (ขั้นตอน 2.1) และตรวจสอบว่าดึง `idToken` มาจาก `googleUser.authentication.idToken` ไม่ใช่ดึงผิดตัวจาก `authorizationClient`

**Error `permission-denied` ตอนกด "โพสต์ขายจริง"** ถ้ายังไม่ได้แก้ Rules ตามส่วนที่ 7 ค่าเริ่มต้นของ Firestore Project ใหม่มักตั้งเป็นโหมด Test Mode ที่หมดอายุใน 30 วัน หรือโหมด Locked ที่ปฏิเสธทุกคำขอ แต่ถ้าแก้ Rules ไปแล้วยัง Error อยู่ ให้ตรวจสอบว่าโค้ดในขั้นตอน 6.3 แนบ `sellerId: FirebaseAuth.instance.currentUser!.uid` ไปกับทุกเอกสารที่สร้างจริงหรือไม่

**กด "โพสต์ขายจริง" ซ้ำสองครั้งแล้วได้สินค้าซ้ำกันสองชิ้นใน Firestore** มักเกิดจากลืมเรียก `draftRepository.deleteDraft(draft.id)` หลังโพสต์สำเร็จ หรือเรียกแล้วแต่ไม่ได้ Refresh รายการบนหน้าจอ ทำให้ผู้ใช้มองไม่เห็นว่าร่างหายไปแล้วและกดปุ่มซ้ำ

**รูปภาพอัปโหลดขึ้น Storage สำเร็จ แต่ `Image.network(imageUrl)` ไม่แสดงผลในแอป** ตรวจสอบว่าโค้ดเรียก `getDownloadURL()` **หลังจาก** `putFile()` อัปโหลดเสร็จสมบูรณ์แล้วจริง (ต้อง `await` ให้ถูกจุด) ไม่ใช่เรียกคู่ขนานกันไป

**แอป Crash ตอนเปิดหน้า "ร่างของฉัน" หรือหน้าดูประกาศของตัวเอง ด้วย Error เกี่ยวกับ Index** Firestore ต้องการ Composite Index เมื่อ Query ที่ซับซ้อน (เช่น `where` ร่วมกับ `orderBy` มากกว่า 1 field) ข้อความ Error จาก Firestore มักแนบลิงก์ให้กดสร้าง Index อัตโนมัติมาด้วยเสมอ ให้กดลิงก์นั้นแล้วรอสักครู่ให้ Index สร้างเสร็จ

---
