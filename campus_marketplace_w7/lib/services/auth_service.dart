import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // นำเข้า Google Sign-In

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleReady = false;

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await _googleSignIn.initialize();
    _googleReady = true;
  }

  // 1. เข้าสู่ระบบด้วย Google
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleReady();

      final googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return; // กรณีผู้ใช้กดยกเลิกการเลือกบัญชี

      final idToken = googleUser.authentication.idToken;
      final authorization = await googleUser.authorizationClient.authorizationForScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // 2. สมัครสมาชิกด้วย Email/Password
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // 3. เข้าสู่ระบบด้วย Email/Password
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // 4. ออกจากระบบ
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  String _translateErrorCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว กรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ';
      case 'weak-password':
        return 'รหัสผ่านสั้นเกินไป กรุณาตั้งรหัสผ่านอย่างน้อย 6 ตัวอักษร';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง';
      case 'invalid-credential':
        return 'ข้อมูลยืนยันตัวตนไม่ถูกต้องหรือหมดอายุ กรุณาลองเข้าสู่ระบบใหม่';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้ในระบบ';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง';
      case 'too-many-requests':
        return 'มีการพยายามทำรายการมากเกินไป กรุณารอสักครู่แล้วลองใหม่';
      default:
        return 'เกิดข้อผิดพลาดในการยืนยันตัวตน (รหัส: $code)';
    }
  }
}