import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What kind of lock this device offers, for labels / icons in the UI.
///
///  • iOS with Face ID      → "Face ID"
///  • iOS with Touch ID     → "Touch ID"
///  • Android               → "Fingerprint" / "Biometric unlock"
///  • nothing enrolled      → available=false (UI explains how to set it up)
class BiometricKind {
  final bool available; // hardware present AND something enrolled
  final bool supported; // hardware/OS supports it at all
  final String title;
  final String subtitle;
  final IconData icon;

  const BiometricKind({
    required this.available,
    required this.supported,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

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

  /// Platform-aware description of the lock (Face ID on iPhone, etc.).
  static Future<BiometricKind> kind() async {
    bool supported = false;
    List<BiometricType> types = const [];
    try {
      supported = await _auth.isDeviceSupported();
      types = await _auth.getAvailableBiometrics();
    } catch (_) {}

    if (Platform.isIOS) {
      if (types.contains(BiometricType.face)) {
        return const BiometricKind(
          available: true,
          supported: true,
          title: 'Face ID',
          subtitle: 'Use Face ID to open BudgetBuddy',
          icon: Icons.face_unlock_rounded,
        );
      }
      if (types.contains(BiometricType.fingerprint)) {
        return const BiometricKind(
          available: true,
          supported: true,
          title: 'Touch ID',
          subtitle: 'Use Touch ID to open BudgetBuddy',
          icon: Icons.fingerprint_rounded,
        );
      }
      return BiometricKind(
        available: false,
        supported: supported,
        title: 'Face ID',
        subtitle: supported
            ? 'Set up Face ID in iOS Settings → Face ID & Passcode'
            : 'Not available on this iPhone',
        icon: Icons.face_unlock_rounded,
      );
    }

    // Android (and anything else)
    final hasFinger =
        types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.strong);
    final hasAny = types.isNotEmpty;
    if (hasAny) {
      return BiometricKind(
        available: true,
        supported: true,
        title: hasFinger ? 'Fingerprint lock' : 'Biometric lock',
        subtitle: hasFinger
            ? 'Use your fingerprint to open BudgetBuddy'
            : 'Use face or fingerprint to open BudgetBuddy',
        icon: Icons.fingerprint_rounded,
      );
    }
    return BiometricKind(
      available: false,
      supported: supported,
      title: 'Biometric lock',
      subtitle: supported
          ? 'Add a fingerprint in Android Settings → Security'
          : 'Not available on this device',
      icon: Icons.fingerprint_rounded,
    );
  }

  static Future<bool> get isEnabled async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key) ?? false;
  }

  static Future<void> setEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, v);
  }

  /// Shows the system prompt (Face ID / Touch ID / fingerprint). Falls back
  /// to the device passcode / PIN if biometrics fail, so users can't get
  /// locked out of their own data.
  static Future<bool> authenticate({
    String reason = 'Unlock BudgetBuddy',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow passcode / PIN fallback
        ),
      );
    } on PlatformException {
      // NotAvailable, PasscodeNotSet, NotEnrolled, LockedOut … → not unlocked
      return false;
    } catch (_) {
      return false;
    }
  }
}
