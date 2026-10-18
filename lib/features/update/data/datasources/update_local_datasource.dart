import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract class UpdateLocalDataSource {
  Stream<double> downloadFile(String url, String savePath);
  Future<void> launchInstaller(String installerPath, {bool silent = true});
  Future<String> getUpdatesDirectory();
}

class UpdateLocalDataSourceImpl implements UpdateLocalDataSource {
  @override
  Stream<double> downloadFile(String url, String savePath) async* {
    if (kIsWeb) {
      throw UnsupportedError('تنزيل الملفات غير مدعوم على متصفح الويب.');
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw HttpException(
          'فشل تنزيل ملف التحديث. رمز الاستجابة من السيرفر: ${response.statusCode}',
        );
      }

      final file = File(savePath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      final fileSink = file.openWrite();
      final totalBytes = response.contentLength;
      var downloadedBytes = 0;

      try {
        await for (final chunk in response) {
          fileSink.add(chunk);
          downloadedBytes += chunk.length;
          if (totalBytes > 0) {
            yield downloadedBytes / totalBytes;
          } else {
            yield -1.0;
          }
        }
      } finally {
        await fileSink.close();
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<void> launchInstaller(String installerPath, {bool silent = true}) async {
    if (kIsWeb) return;
    if (!Platform.isWindows) {
      throw UnsupportedError('تثبيت التحديث مدعوم فقط على بيئة Windows.');
    }

    if (installerPath.toLowerCase().endsWith('.exe')) {
      final List<String> args = silent
          ? [
              '/VERYSILENT',
              '/SUPPRESSMSGBOXES',
              '/SP-',
              '/CLOSEAPPLICATIONS',
              '/NORESTART',
              '/MERGETASKS=!desktopicon',
            ]
          : [];

      await Process.start(
        installerPath,
        args,
        mode: ProcessStartMode.detached,
      );

      // Short delay to let the OS spawn the detached process safely before exit
      await Future<void>.delayed(const Duration(milliseconds: 400));
      exit(0);
    } else {
      throw UnsupportedError('صيغة ملف التثبيت غير مدعومة. يدعم فقط ملفات .exe');
    }
  }

  @override
  Future<String> getUpdatesDirectory() async {
    if (Platform.isWindows) {
      return p.join(
        Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path,
        'SalesManagerUpdates',
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      return p.join(dir.path, 'SalesManagerUpdates');
    }
  }
}
