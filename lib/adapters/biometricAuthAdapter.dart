import 'package:flutter/cupertino.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthAdapter {
  static final _auth = LocalAuthentication();

  static Future<bool> canUse() async =>
      await _auth.canCheckBiometrics || await _auth.isDeviceSupported();

  static Future<bool> login() async{
    try{
      return await _auth.authenticate(
          localizedReason: "Use fingerprint to login",
          options: const AuthenticationOptions(
              useErrorDialogs: true,
              stickyAuth: true,
              biometricOnly: true
          )
      );

    }catch (e) {
      debugPrint('Auth login error: $e');
      return false;
    }

  }

}