import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class FileExportHelper {
  FileExportHelper._();

  /// Buka preview file yang baru diekspor.
  static Future<void> openFile(File file) async {
    await OpenFilex.open(file.path);
  }

  /// Bagikan file (via share sheet).
  static Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)],
        subject: file.uri.pathSegments.last);
  }
}
