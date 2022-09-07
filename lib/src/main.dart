import 'dart:io';

import 'package:did_change_authlocal/src/status_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DidChangeAuthLocal {
  final methodChannel = const MethodChannel('did_change_authlocal');
  DidChangeAuthLocal._internal();

  static final DidChangeAuthLocal _instance = DidChangeAuthLocal._internal();

  static DidChangeAuthLocal get instance => _instance;

  Future<BiometricStatus?> onCheckBiometric({String? token}) async {
    return Platform.isIOS
        ? await checkBiometricIOS(token: token ?? '')
        : await checkBiometricAndroid();
  }

  Future<String> getTokenBiometric() async {
    try {
      final result = await methodChannel.invokeMethod('get_token');
      return result.toString();
    } catch (_) {
      return '';
    }
  }

  Future<BiometricStatus?> checkBiometricIOS({String token = ''}) async {
    try {
      final result = await methodChannel.invokeMethod('get_token');
      debugPrint("checkBiometricIOS Token: ${result.toString()}");
      debugPrint("checkBiometricIOS Token Local: ${token.toString()}");
      if (token == result && token.isNotEmpty) {
        return BiometricStatus.valid;
      } else if (token != result && token != '') {
        return BiometricStatus.changed;
      } else {
        return BiometricStatus.invalid;
      }
    } on PlatformException catch (e) {
      switch (e.code) {
        case "biometric_invalid":
          return BiometricStatus.invalid;
        default:
          return null;
      }
    }
  }

  Future<BiometricStatus?> checkBiometricAndroid() async {
    try {
      final result = await methodChannel.invokeMethod('check');
      return result == 'biometric_valid' ? BiometricStatus.valid : null;
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'biometric_did_change':
          return BiometricStatus.changed;
        case 'biometric_invalid':
          return BiometricStatus.invalid;
        default:
          return BiometricStatus.invalid;
      }
    } on MissingPluginException catch (e) {
      debugPrint(e.message);
      return null;
    }
  }
}