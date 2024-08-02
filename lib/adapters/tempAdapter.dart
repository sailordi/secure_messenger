import 'dart:io';
import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';

import 'package:path_provider/path_provider.dart';

class TempAdapter {

  static Future<Directory> getTempDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final appTempDir = Directory('${tempDir.path}/my_app');

    if (!await appTempDir.exists()) {
      await appTempDir.create(recursive: true);
    }

    return appTempDir;
  }

  Future<File> writeUint8ListToFile(Uint8List uint8List,String fileName) async {
    final directory = await getTempDirectory();
    final filePath = '${directory.path}/$fileName';

    File file = File(filePath);
    return await file.writeAsBytes(uint8List as List<int>);
  }

  static Future<void> clearTempDirectory() async {
    final directory = await getTempDirectory();

    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }

  }

}