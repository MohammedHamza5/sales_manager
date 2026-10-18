// ignore_for_file: avoid_print, prefer_final_locals
import 'dart:convert';
import 'dart:io';

const String supabaseUrl = 'https://xxhqzdeymxrekeizzbws.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4aHF6ZGV5bXhyZWtlaXp6YndzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzNjc0NTMsImV4cCI6MjEwNTk0MzQ1M30.fvoHlVhYy4UnyeVTeO5EubBDtUdxk6CFD23f--7F1e0';

void main(List<String> args) async {
  print('=====================================================');
  print('🚀 نظام النشر التلقائي للتحديثات الهوائية (Sales Manager)');
  print('=====================================================\n');

  if (args.contains('-h') || args.contains('--help')) {
    _printHelp();
    return;
  }

  final bool skipBuild = args.contains('--skip-build') || args.contains('-s');
  final bool isRequired = args.contains('--required') || args.contains('-r');

  String? customVersion = _getArgValue(args, '--version', '-v');
  String releaseNotes = _getArgValue(args, '--notes', '-n') ??
      '• تحسينات عامة في أداء واستقرار النظام\n• تحديثات دورية لقاعدة البيانات والواجهات';

  // 1. Read current version from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ خطأ: لم يتم العثور على ملف pubspec.yaml في المجلد الحالي.');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final versionMatch = RegExp(r'^version:\s*([^\s\r\n]+)', multiLine: true).firstMatch(pubspecContent);
  if (versionMatch == null) {
    print('❌ خطأ: تعذر قراءة حقل version من pubspec.yaml.');
    exit(1);
  }

  final currentFullVersion = versionMatch.group(1)!;
  final currentCoreVersion = currentFullVersion.split('+')[0];
  final currentBuildNumber = currentFullVersion.contains('+')
      ? int.tryParse(currentFullVersion.split('+')[1]) ?? 1
      : 1;

  print('📌 الإصدار الحالي في المشروع: $currentFullVersion');

  // Determine target new version
  final String newVersion;
  final int newBuildNumber = currentBuildNumber + 1;

  if (customVersion != null && customVersion.isNotEmpty) {
    newVersion = customVersion.replaceAll('v', '').trim();
  } else {
    // Auto-bump patch version: e.g., 1.0.0 -> 1.0.1
    final parts = currentCoreVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    parts[2] = parts[2] + 1;
    newVersion = parts.join('.');
  }

  final newFullVersion = '$newVersion+$newBuildNumber';
  print('🎯 الإصدار الجديد المستهدف: $newFullVersion');
  print('📝 ملاحظات التحديث:\n$releaseNotes');
  print('🔒 تحديث إلزامي: ${isRequired ? "نعم" : "لا"}\n');

  // 2. Update pubspec.yaml
  final updatedPubspec = pubspecContent.replaceFirst(
    RegExp(r'^version:\s*.+$', multiLine: true),
    'version: $newFullVersion',
  );
  pubspecFile.writeAsStringSync(updatedPubspec);
  print('✅ تم تحديث pubspec.yaml إلى: $newFullVersion');

  // 3. Update app_config.dart
  final appConfigFile = File('lib/core/config/app_config.dart');
  if (appConfigFile.existsSync()) {
    var configContent = appConfigFile.readAsStringSync();
    configContent = configContent.replaceFirst(
      RegExp(r"static const String appVersion = '[^']*';"),
      "static const String appVersion = '$newVersion';",
    );
    appConfigFile.writeAsStringSync(configContent);
    print('✅ تم تحديث app_config.dart إلى: $newVersion');
  }

  // 4. Build Flutter Release
  if (!skipBuild) {
    print('\n🔨 جاري بناء النسخة التوزيعية (flutter build windows --release)...');
    final buildProcess = await Process.start(
      'flutter',
      ['build', 'windows', '--release'],
      mode: ProcessStartMode.inheritStdio,
      runInShell: true,
    );
    final exitCode = await buildProcess.exitCode;
    if (exitCode != 0) {
      print('❌ فشل بناء مشروع Flutter. كود الخروج: $exitCode');
      exit(exitCode);
    }
    print('✅ اكتمل بناء النسخة التوزيعية بنجاح.');
  } else {
    print('⏭️ تم تخطي خطوة بناء Flutter (--skip-build).');
  }

  // 5. Compile with Inno Setup
  print('\n📦 جاري تجميع ملف التثبيت بواسطة Inno Setup...');
  final isccPath = _findInnoSetupCompiler();
  if (isccPath == null) {
    print('❌ خطأ: لم يتم العثور على Inno Setup Compiler (ISCC.exe).');
    print('يرجى التأكد من تثبيت Inno Setup 6 في المسار الافتراضي.');
    exit(1);
  }

  final isccProcess = await Process.start(
    isccPath,
    [
      '/DMyAppVersion=$newVersion',
      r'installer\sales_manager_installer.iss',
    ],
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
  );
  final isccExitCode = await isccProcess.exitCode;
  if (isccExitCode != 0) {
    print('❌ فشل تجميع مثبت Inno Setup. كود الخروج: $isccExitCode');
    exit(isccExitCode);
  }

  final setupFile = File(r'installer\Output\SalesManager_Setup.exe');
  if (!setupFile.existsSync()) {
    print('❌ خطأ: لم يتم العثور على ملف المثبت الناتج في: ${setupFile.path}');
    exit(1);
  }

  final fileSizeMB = (setupFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
  print('✅ تم تجميع المثبت بنجاح: ${setupFile.path} ($fileSizeMB MB)');

  // 6. Upload Installer to Supabase Storage
  final storageFileName = 'SalesManager_Setup.exe';
  print('\n☁️ جاري رفع ملف التثبيت إلى سحابة Supabase Storage (Bucket: updates)...');

  final uploadSuccess = await _uploadToSupabaseStorage(setupFile, storageFileName);
  if (!uploadSuccess) {
    print('❌ فشل رفع الملف إلى سوبابيز.');
    exit(1);
  }

  final publicDownloadUrl = '$supabaseUrl/storage/v1/object/public/updates/$storageFileName';
  print('✅ تم رفع المثبت بنجاح! الرابط المباشر:\n   $publicDownloadUrl');

  // 7. Insert new version record into app_versions table
  print('\n📡 جاري تسجيل التحديث الجديد في جدول app_versions...');
  final insertSuccess = await _insertAppVersion(
    version: newVersion,
    platform: 'windows',
    downloadUrl: publicDownloadUrl,
    releaseNotes: releaseNotes,
    isRequired: isRequired,
  );

  if (!insertSuccess) {
    print('❌ فشل تسجيل بيانات التحديث في قاعدة البيانات.');
    exit(1);
  }

  print('\n=====================================================');
  print('🎉 تم إرسال ونشر التحديث بنجاح تام!');
  print('=====================================================');
  print('📌 الإصدار الجديد: $newVersion');
  print('🌐 رابط التنزيل: $publicDownloadUrl');
  print('🔔 حالة التنبيه: سيتلقى جميع المستخدمين إشعار التحديث فور فتح البرنامج!');
  print('=====================================================\n');
}

String? _findInnoSetupCompiler() {
  const possiblePaths = [
    r'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    r'C:\Program Files\Inno Setup 6\ISCC.exe',
    r'C:\Program Files (x86)\Inno Setup 5\ISCC.exe',
  ];

  for (final p in possiblePaths) {
    if (File(p).existsSync()) {
      return p;
    }
  }

  try {
    final result = Process.runSync('where', ['iscc']);
    if (result.exitCode == 0) {
      final line = result.stdout.toString().split('\r\n').first.trim();
      if (line.isNotEmpty && File(line).existsSync()) {
        return line;
      }
    }
  } catch (_) {}

  return null;
}

Future<bool> _uploadToSupabaseStorage(File file, String destinationName) async {
  // Use native Dart HttpClient


  // 2. Fallback to native Dart HttpClient
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 60);

  try {
    final url = Uri.parse('$supabaseUrl/storage/v1/object/updates/$destinationName');

    final request = await client.postUrl(url);
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('Content-Type', 'application/octet-stream');
    request.headers.set('x-upsert', 'true');
    request.contentLength = file.lengthSync();
    await request.addStream(file.openRead());

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      print('⚠️ خطأ في رفع السحابة: (${response.statusCode}) $responseBody');
      return false;
    }
  } catch (e) {
    print('⚠️ استثناء أثناء الرفع: $e');
    return false;
  } finally {
    client.close();
  }
}

Future<bool> _insertAppVersion({
  required String version,
  required String platform,
  required String downloadUrl,
  required String releaseNotes,
  required bool isRequired,
}) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 20);

  try {
    final url = Uri.parse('$supabaseUrl/rest/v1/app_versions');
    final request = await client.postUrl(url);

    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Prefer', 'return=representation');

    final body = jsonEncode({
      'version': version,
      'platform': platform,
      'download_url': downloadUrl,
      'release_notes': releaseNotes,
      'is_required': isRequired,
    });

    request.add(utf8.encode(body));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      print('⚠️ خطأ أثناء حفظ التحديث في قاعدة البيانات: (${response.statusCode}) $responseBody');
      return false;
    }
  } catch (e) {
    print('⚠️ استثناء أثناء تسجيل التحديث: $e');
    return false;
  } finally {
    client.close();
  }
}

String? _getArgValue(List<String> args, String longKey, String shortKey) {
  for (int i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('$longKey=')) {
      return arg.substring('$longKey='.length);
    }
    if (arg == longKey || arg == shortKey) {
      if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
        return args[i + 1];
      }
    }
  }
  return null;
}

void _printHelp() {
  print('''
طريقة الاستخدام:
  dart run tools/publish_update.dart [خيارات]

الخيارات:
  -v, --version=<version>   رقم الإصدار الجديد (افتراضياً: يتم زيادة رقم التصحيح تلقائياً: 1.0.0 -> 1.0.1)
  -n, --notes=<text>        ملاحظات وسجل التغييرات التي تظهر للمستخدم
  -r, --required            تحديد ما إذا كان التحديث إجبارياً
  -s, --skip-build          تخطي خطوة flutter build windows (إذا كان تم البناء مسبقاً)
  -h, --help                عرض رسالة المساعدة هذه

أمثلة:
  # إرسال تحديث عادي تلقائي الترقيم وبناء المشروع والمثبت ورفعه:
  dart run tools/publish_update.dart

  # إرسال تحديث محدد برقم إصدار وملاحظات:
  dart run tools/publish_update.dart -v 1.0.2 -n "إصلاح خطأ في الفواتير وإضافة ميزة الطباعة"

  # إرسال تحديث تم بناؤه بالفعل دون إعادة البناء:
  dart run tools/publish_update.dart -s -v 1.0.2
''');
}
