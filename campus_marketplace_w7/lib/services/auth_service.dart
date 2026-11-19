import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleReady = false;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  static const _serverClientId =
      '692891860951-ri8kl00apllovtgv3dj61sjg4n9i0ueq.apps.googleusercontent.com';

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await _googleSignIn.initialize(
      serverClientId: _serverClientId,
    );
    _googleReady = true;
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการลงทะเบียน: $e');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการเข้าสู่ระบบ: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      try {
        await _ensureGoogleReady();
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignored if not signed in with Google
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการออกจากระบบ: $e');
    }
  }

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
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการเข้าสู่ระบบด้วย Google: $e');
    }
  }

  String _translateErrorCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานไปแล้ว กรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ';
      case 'invalid-email':
        return 'รูปแบบที่อยู่อีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้งานที่ใช้อีเมลนี้';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง';
      case 'invalid-credential':
        return 'ข้อมูลยืนยันตัวตนไม่ถูกต้องหรือหมดอายุ กรุณาลองใหม่อีกครั้ง';
      case 'user-disabled':
        return 'บัญชีผู้ใช้นี้ถูกระงับการใช้งาน';
      case 'too-many-requests':
        return 'มีการส่งคำขอมากเกินไป กรุณารอสักครู่แล้วลองใหม่';
      case 'operation-not-allowed':
        return 'ระบบยังไม่ได้เปิดให้เข้าสู่ระบบด้วยวิธีนี้';
      case 'network-request-failed':
        return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ';
      default:
        return 'เกิดข้อผิดพลาด ($code) กรุณาลองใหม่อีกครั้ง';
    }
  }
}
