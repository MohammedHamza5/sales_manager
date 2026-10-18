# دليل نظام التحديثات عن بُعد (OTA Updates System)
> الإصدار: 1.0 · نظام إدارة المبيعات والمخزون والحسابات

---

## 1. نبذة عن النظام ومبدأ العمل
تم تزويد المشروع بنظام تحديثات هوائي (Over-The-Air) مماثل ومعياري لنظام التحديث في مشروع `stream_pay` مع مواءمة تامة لمعمارية `Cubit` و `Clean Architecture`:
- **الجهة السحابية (Cloud):** جدول `public.app_versions` على Supabase مفعل عليه RLS مع سياسة قراءة عامة للتحقق من التحديثات بأمان.
- **التحقق التلقائي (Auto-Check):** عند فتح التطبيق، يفحص النظام في الخلفية أحدث إصدار متاح لمنصة Windows (`windows` أو `windows_offline`).
- **المقارنة الذكية (SemVer Comparison):** يقارن النظام الإصدار الحالي (المستخرج عبر `PackageInfo` مع دعم Fallback إلى `AppConfig.appVersion`) مع الإصدار السحابي.
- **التنبيه الفوري:** عند توفر إصدار أحدث، تظهر نافذة تفاعلية راقية `UpdateDialog` تعرض رقم الإصدار وسجل التغييرات (`Release Notes`).
- **التنزيل والتثبيت الذاتي (Silent Background Install):**
  - يتم تنزيل ملف التحديث (`.exe`) تدريجياً مع مؤشر تقدم مباشر (`LinearProgressIndicator`).
  - عند اكتمال التنزيل، يُشغّل التطبيق مثبت Inno Setup في وضع الصامت المعزول (`Detached Process`) باستخدام المفاتيح:
    `/VERYSILENT /SUPPRESSMSGBOXES /SP- /CLOSEAPPLICATIONS /NORESTART /MERGETASKS=!desktopicon`
  - يُغلق التطبيق تلقائياً وتُستبدل الملفات فورياً في مسار `{localappdata}\SalesManager` دون الحاجة لصلاحيات Administrator ثم يُعاد فتح التطبيق بنسخته الجديدة!
- **التحقق اليدوي:** عبر شاشة **الإعدادات > تحديثات النظام**، يمكن للمستخدم في أي وقت الضغط على زر "التحقق من وجود تحديثات" ومتابعة حالة التحديث.

---

## 2. خطوات إرسال تحديث جديد للمستخدمين (Release Workflow)

### الخطوة 1: تحديث رقم الإصدار في المشروع
في ملف `pubspec.yaml`:
```yaml
version: 1.0.1+2 # قم بتحديث الرقم مثل 1.0.1
```
وفي ملف `lib/core/config/app_config.dart`:
```dart
static const String appVersion = '1.0.1';
```

### الخطوة 2: بناء النسخة التوزيعية (Release Build)
افتح الطرفية (Terminal) ونفذ الأمر:
```powershell
flutter build windows --release
```
سينتج مجلد البرنامج الجديد في: `build\windows\x64\runner\Release`

### الخطوة 3: تجميع ملف التثبيت بواسطة Inno Setup
1. افتح برنامج Inno Setup Compiler.
2. افتح الملف الجاهز: `installer\sales_manager_installer.iss`.
3. اضغط **Compile** (أو `Ctrl + F9`).
4. سينتج ملف المثبت في: `installer\Output\SalesManager_Setup.exe`.

### الخطوة 4: رفع المثبت إلى السحابة
ارفع ملف `SalesManager_Setup.exe` إلى:
- Supabase Storage (Bucket عام مثل `updates` أو `releases`)
- أو GitHub Releases
- أو Google Drive (رابط تنزيل مباشر)
- أو أي خادم ويب يوفر رابط تنزيل مباشر (Direct Download URL).

### الخطوة 5: نشر التحديث في قاعدة البيانات (Supabase)
نفذ استعلام SQL التالي من لوحة تحكم Supabase SQL Editor:

```sql
INSERT INTO public.app_versions (
    version,
    platform,
    download_url,
    release_notes,
    is_required
) VALUES (
    '1.0.1',
    'windows',
    'https://xxhqzdeymxrekeizzbws.supabase.co/storage/v1/object/public/updates/SalesManager_Setup.exe',
    '• إصلاحات عامة في أداء النظام\n• إضافة ميزات جديدة وتحسين سرعة استعلام التقارير\n• تعزيز دقة الطباعة الحرارية',
    false -- اجعلها true إذا كان التحديث إلزامياً
);
```

> بمجرد تشغيل هذا الاستعلام، سيظهر التحديث تلقائياً لأي مستخدم يفتح التطبيق أو يفحص التحديثات!
