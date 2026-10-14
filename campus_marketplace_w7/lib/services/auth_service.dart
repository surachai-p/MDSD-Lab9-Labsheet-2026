import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleReady = false;

  // สมัครสมาชิก
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // เข้าสู่ระบบ
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // ออกจากระบบ
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // initialize() ต้องเรียกครั้งเดียวก่อนใช้งานเมธอดอื่นของ GoogleSignIn เสมอ
  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await _googleSignIn.initialize();
    _googleReady = true;
  }

  // เข้าสู่ระบบด้วย Google
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleReady();

      // เปิดหน้าต่างให้ผู้ใช้เลือกบัญชี Google
      final googleUser = await _googleSignIn.authenticate();

      // idToken: หลักฐานระบุตัวตนผู้ใช้
      final idToken = googleUser.authentication.idToken;

      // accessToken: ต้องขอแยกผ่าน authorizationClient
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );

      // ส่งให้ Firebase ยืนยันและสร้าง/ล็อกอินบัญชี
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // แปล error code ของ Firebase เป็นข้อความภาษาไทย
  String _translateErrorCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้สมัครสมาชิกแล้ว';
      case 'weak-password':
        return 'รหัสผ่านสั้นหรือเดาง่ายเกินไป (ต้องมีอย่างน้อย 6 ตัวอักษร)';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง หรือข้อมูลยืนยันตัวตนหมดอายุ';
      case 'user-disabled':
        return 'บัญชีนี้ถูกระงับการใช้งาน';
      case 'too-many-requests':
        return 'ลองบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่';
      case 'network-request-failed':
        return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
      default:
        return 'เกิดข้อผิดพลาด ($code) กรุณาลองใหม่อีกครั้ง';
    }
  }
}