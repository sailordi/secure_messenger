import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageAdapter {
  final String _emailKey = "Email";
  final String _passKey = "Pass";
  final _storage = const FlutterSecureStorage();

  Future<void> storeUser(String email,String password) async {
    await _storage.write(key:_emailKey, value: email);
    await _storage.write(key:_passKey, value: password);
  }

  Future<(String?,String?)> getUser() async{
    String? email = await _storage.read(key: _emailKey);
    String? pass = await _storage.read(key: _passKey);

    return (email,pass);
  }

}