import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _key = 'biometric_enabled';

  static Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> get isEnabled async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key) ?? false;
  }

  static Future<void> setEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, v);
  }

  static Future<bool> authenticate({
    String reason = 'Authenticate to open SpendSense',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow PIN fallback
        ),
      );
    } on PlatformException catch (e) {
      // NotAvailable, PasscodeNotSet, NotEnrolled → treat as skip
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.passcodeNotSet ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
