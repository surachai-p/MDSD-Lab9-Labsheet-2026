import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleReady = false;

  // Stream สำหรับติดตามสถานะการล็อกอิน (ใช้ใน AuthGate)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ดึงข้อมูลผู้ใช้ปัจจุบัน
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    // initialize() ต้องเรียกครั้งเดียวก่อนใช้งานเมธอดอื่นของ GoogleSignIn เสมอ
    await _googleSignIn.initialize(
      serverClientId: '819812355771-q5vpv74kg5jch7n28pnlq4fsff7rt8q4.apps.googleusercontent.com',
    );
    _googleReady = true;
  }

  /// เมธอดสมัครสมาชิกใหม่ด้วย Email และ Password
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// เมธอดเข้าสู่ระบบด้วย Email และ Password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// เมธอดเข้าสู่ระบบด้วย Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleReady();

      // authenticate() เปิดหน้าต่างให้ผู้ใช้เลือกบัญชี Google (แทนที่ signIn() ในเวอร์ชันเก่า)
      final googleUser = await _googleSignIn.authenticate();

      // idToken ได้แบบ synchronous จาก authentication ของบัญชีที่ล็อกอินแล้ว
      final idToken = googleUser.authentication.idToken;

      // accessToken ต้องขอเพิ่มผ่าน authorizationClient แยกต่างหาก
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  /// เมธอดออกจากระบบ
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการออกจากระบบ');
    }
  }

  /// แปลงรหัส Error (code) จาก Firebase เป็นข้อความภาษาไทยที่เข้าใจง่าย
  String _translateErrorCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานไปแล้ว กรุณาใช้อีเมลอื่น';
      case 'weak-password':
        return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'invalid-credential':
        return 'ข้อมูลยืนยันตัวตนจาก Google ไม่ถูกต้องหรือหมดอายุ กรุณาลองเข้าสู่ระบบใหม่';
      case 'user-not-found':
      case 'wrong-password':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีผู้ใช้นี้ถูกระงับการใช้งาน';
      case 'too-many-requests':
        return 'มีการพยายามเข้าสู่ระบบผิดพลาดบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่';
      case 'network-request-failed':
        return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบสัญญาณเน็ต';
      case 'operation-not-allowed':
        return 'ระบบลงทะเบียนด้วยวิธีนี้ยังไม่เปิดใช้งานใน Firebase Console';
      default:
        return 'เกิดข้อผิดพลาด: $code';
    }
  }
}
