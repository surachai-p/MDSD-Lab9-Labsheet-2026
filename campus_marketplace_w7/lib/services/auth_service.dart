import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static Future<void>? _googleInitialization;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error.code));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error.code));
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error.code));
    }
  }

  Future<void> _ensureGoogleReady() =>
      _googleInitialization ??= _googleSignIn.initialize();

  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleReady();

      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageFor(error.code));
    }
  }

  String _messageFor(String code) {
    return switch (code) {
      'email-already-in-use' => 'อีเมลนี้ถูกใช้สมัครสมาชิกแล้ว',
      'weak-password' =>
        'รหัสผ่านสั้นหรือคาดเดาง่ายเกินไป (ต้องมีอย่างน้อย 6 ตัวอักษร)',
      'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
      'invalid-credential' =>
        'ข้อมูลยืนยันตัวตนจาก Google ไม่ถูกต้องหรือหมดอายุ กรุณาลองเข้าสู่ระบบใหม่',
      'invalid-login-credentials' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
      'user-not-found' => 'ไม่พบบัญชีผู้ใช้นี้',
      'wrong-password' => 'รหัสผ่านไม่ถูกต้อง',
      'user-disabled' => 'บัญชีนี้ถูกระงับการใช้งาน',
      'operation-not-allowed' => 'ยังไม่ได้เปิดใช้งานวิธีเข้าสู่ระบบนี้',
      'too-many-requests' => 'ลองเข้าสู่ระบบหลายครั้งเกินไป กรุณารอสักครู่',
      'network-request-failed' =>
        'เชื่อมต่อไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง',
      'requires-recent-login' => 'กรุณาเข้าสู่ระบบใหม่อีกครั้งก่อนดำเนินการนี้',
      _ => 'เกิดข้อผิดพลาดในการยืนยันตัวตน กรุณาลองอีกครั้ง',
    };
  }
}

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}
