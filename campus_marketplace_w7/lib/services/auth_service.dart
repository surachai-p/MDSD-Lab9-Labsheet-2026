import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'เกิดข้อผิดพลาดในการสมัครสมาชิก: $e';
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ: $e';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    } catch (e) {
      throw 'เกิดข้อผิดพลาดในการออกจากระบบ: $e';
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '387966785221-t3dgpu73mp5p8ea05hrbm2itd97ubop2.apps.googleusercontent.com',
        nonce: '12345678901234567890',
      );
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await GoogleSignIn.instance.authenticate();
      } catch (e) {
        try {
          googleUser =
              await GoogleSignIn.instance.attemptLightweightAuthentication();
        } catch (_) {}
      }

      if (googleUser != null) {
        final idToken = googleUser.authentication.idToken;
        final authorization =
            await googleUser.authorizationClient.authorizationForScopes(['email']);
        final accessToken = authorization?.accessToken;

        final credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: accessToken,
        );

        return await _auth.signInWithCredential(credential);
      }

      // หาก Google Play Services บน Emulator มีบั๊กของระบบ ให้ใช้ Web Flow (Chrome Custom Tab) ยืนยันตัวตนแทน
      final googleProvider = GoogleAuthProvider();
      return await _auth.signInWithProvider(googleProvider);

    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('canceled')) {
        return null;
      }
      throw 'เข้าสู่ระบบด้วย Google ไม่สำเร็จ: $e';
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานไปแล้ว กรุณาใช้อีเมลอื่น';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้ในระบบ';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง';
      case 'user-disabled':
        return 'บัญชีผู้ใช้นี้ถูกระงับการใช้งาน';
      case 'operation-not-allowed':
        return 'วิธีเข้าสู่ระบบนี้ยังไม่เปิดใช้งานในระบบ';
      case 'network-request-failed':
        return 'การเชื่อมต่อล้มเหลว กรุณาตรวจสอบสัญญาณอินเทอร์เน็ต';
      case 'too-many-requests':
        return 'พยายามเข้าสู่ระบบบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่';
      default:
        return 'เกิดข้อผิดพลาด (${e.code}): ${e.message ?? 'กรุณาลองใหม่อีกครั้ง'}';
    }
  }
}
