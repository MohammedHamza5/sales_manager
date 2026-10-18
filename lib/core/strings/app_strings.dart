abstract final class AppStrings {
  // اسم التطبيق
  static const appName = 'Sales Manager';
  static const appSubtitle = 'نظام إدارة المبيعات والمخزون والحسابات';

  // الوحدات الرئيسية (Navigation)
  static const dashboard = 'لوحة التحكم';
  static const products = 'المنتجات';
  static const inventory = 'المخزون';
  static const inventoryMovements = 'حركة المخزون';
  static const stockAdjustments = 'تسويات المخزون';
  static const customers = 'العملاء';
  static const customerLedger = 'كشف حساب العميل';
  static const suppliers = 'الموردون';
  static const supplierLedger = 'كشف حساب المورد';
  static const sales = 'المبيعات';
  static const newSale = 'فاتورة بيع جديدة';
  static const purchases = 'المشتريات';
  static const newPurchase = 'فاتورة شراء جديدة';
  static const customerPayments = 'تحصيلات العملاء';
  static const supplierPayments = 'مدفوعات الموردين';
  static const cashbox = 'الخزينة';
  static const expenses = 'المصروفات';
  static const returns = 'المرتجعات';
  static const openingBalance = 'الأرصدة الافتتاحية';
  static const reports = 'التقارير';
  static const settings = 'الإعدادات';
  static const auditLog = 'سجل التتبع والعمليات';
  static const backupRestore = 'النسخ الاحتياطي والاستعادة';

  // الحالات العامة
  static const loading = 'جاري التحميل...';
  static const emptyData = 'لا توجد بيانات متاحة حالياً';
  static const retry = 'إعادة المحاولة';
  static const search = 'بحث...';
  static const filter = 'تصفية';
  static const save = 'حفظ';
  static const cancel = 'إلغاء';
  static const confirm = 'تأكيد';
  static const delete = 'حذف';
  static const edit = 'تعديل';
  static const add = 'إضافة';
  static const print = 'طباعة';
  static const export = 'تصدير';
  static const date = 'التاريخ';
  static const notes = 'ملاحظات';
  static const status = 'الحالة';
  static const actions = 'الإجراءات';

  // التنبيهات والأخطاء
  static const successOperation = 'تمت العملية بنجاح';
  static const failureOperation = 'حدث خطأ أثناء تنفيذ العملية';
  static const requiredField = 'هذا الحقل مطلوب';
  static const invalidNumber = 'رقم غير صحيح';
  static const insufficientStock = 'الكمية المطلوبة تتجاوز الرصيد المتاح بالمخزن';

  // العملات والوحدات
  static const currencyPound = 'ج.م';
  static const piastre = 'قرش';

  // المبيعات والمرتجعات
  static const invoiceNo = 'رقم الفاتورة';
  static const invoiceDate = 'تاريخ الفاتورة';
  static const customerName = 'اسم العميل';
  static const supplierName = 'اسم المورد';
  static const productName = 'اسم المنتج';
  static const quantity = 'الكمية';
  static const unitPrice = 'سعر الوحدة';
  static const lineTotal = 'الإجمالي';
  static const totalAmount = 'إجمالي الفاتورة';
  static const paidAmount = 'المدفوع';
  static const remainingAmount = 'المتبقي';
  static const confirmed = 'مؤكدة';
  static const reversed = 'مُلغاة (معكوسة)';
  static const reverseInvoice = 'إلغاء وعكس الفاتورة';
  static const reverseSuccess = 'تم عكس العملية بنجاح';
  static const reverseConfirmTitle = 'تأكيد إلغاء العملية';
  static const reverseConfirmMessage = 'هل أنت متأكد من إلغاء وعكس هذه الفاتورة؟ سيتم عكس المخزون وحساب العميل والخزينة تلقائياً وبأثر رجعي.';
  static const addItem = 'إضافة صنف';
  static const removeItem = 'حذف الصنف';
  static const customerReturns = 'مرتجعات العملاء';
  static const supplierReturns = 'مرتجعات الموردين';
  static const newCustomerReturn = 'مرتجع عميل جديد';
  static const newSupplierReturn = 'مرتجع مورد جديد';
  static const originalInvoice = 'الفاتورة الأصلية';
  static const selectCustomer = 'اختر العميل';
  static const selectSupplier = 'اختر المورد';
  static const selectProduct = 'اختر المنتج';
  static const cashSale = 'نقدي';
  static const creditSale = 'آجل';
  static const partialSale = 'جزئي';
  static const salesCount = 'عدد الفواتير';
  static const totalSales = 'إجمالي المبيعات';
  static const totalPaid = 'إجمالي المحصل';
  static const totalRemaining = 'إجمالي الآجل';
  static const returnReason = 'سبب المرتجع';
  static const totalReturns = 'إجمالي المرتجعات';

  // النسخ الاحتياطي والاستعادة
  static const backup = 'النسخ الاحتياطي';
  static const restore = 'استعادة البيانات';
  static const manualBackup = 'نسخ احتياطي يدوي';
  static const createBackup = 'إنشاء نسخة احتياطية الآن';
  static const exportToUsb = 'تصدير لمسار خارجي / USB';
  static const autoBackup = 'النسخ الاحتياطي التلقائي';
  static const enableAutoBackup = 'تفعيل النسخ الاحتياطي التلقائي عند بدء التشغيل';
  static const autoBackupRetention = 'عدد النسخ التلقائية المحتفظ بها';
  static const restoreBackup = 'استعادة نسخة احتياطية';
  static const chooseBackupFile = 'اختيار ملف نسخة احتياطية (.sqlite)';
  static const restoreWarningTitle = 'تأكيد استبدال واستعادة البيانات';
  static const restoreWarningMessage =
      'تنبيه فائق الأهمية: سيتم استبدال قاعدة البيانات الحالية بالكامل بالملف المختار.\n\n'
      'سيقوم النظام بأخذ نسخة أمان احترازية من البيانات الحالية تلقائياً قبل البدء.\n'
      'هل ترغب بالتأكيد والمتابعة؟';
  static const restoreSuccess = 'تمت استعادة النسخة الاحتياطية بنجاح.';
  static const backupCreatedSuccess = 'تم إنشاء النسخة الاحتياطية بنجاح في:';
  static const backupHistory = 'سجل النسخ الاحتياطية السابقة';
  static const backupType = 'النوع';
  static const backupSize = 'الحجم';
  static const backupPath = 'المسار';
  static const backupManual = 'يدوي';
  static const backupAuto = 'تلقائي';
  static const backupExport = 'تصدير خارجي';
  static const schemaVersion = 'إصدار المخطط';
  static const invalidBackupFile = 'ملف النسخة الاحتياطية غير صالح أو تالف';
  static const incompatibleSchemaVersion = 'إصدار قاعدة البيانات في النسخة الاحتياطية غير متوافق مع التطبيق الحالي';
  static const restartAppNotice = 'يرجى إعادة تشغيل التطبيق لتطبيق كافة التغييرات المستعادة بشكل كامل.';

  // سجل التتبع والعمليات (Audit Log)
  static const auditLogSubtitle = 'متابعة وتدقيق كافة الحركات والتعديلات التي تمت على النظام';
  static const entityType = 'نوع الكيان';
  static const actionType = 'نوع الإجراء';
  static const performedAt = 'التاريخ والوقت';
  static const performedBy = 'المستخدم';
  static const details = 'التفاصيل';
  static const allEntities = 'كافة الكيانات';
  static const allActions = 'كافة الإجراءات';
  static const dateFrom = 'من تاريخ';
  static const dateTo = 'إلى تاريخ';
  static const payloadBefore = 'البيانات السابقة (قبل الإجراء)';
  static const payloadAfter = 'البيانات الجديدة (بعد الإجراء)';
  static const noChanges = 'لا توجد فروق مسجلة';
  static const auditDetails = 'تفاصيل سجل التدقيق';

  // الطباعة
  static const printThermal = 'طباعة إيصال كاشير (80mm)';
  static const printA4 = 'طباعة فاتورة قياسية (A4)';
  static const printReceipt = 'طباعة إيصال';
  static const printInvoice = 'طباعة فاتورة';
  static const printStatement = 'طباعة كشف الحساب';
  static const printReport = 'طباعة التقرير';
  static const thankYou = 'شكراً لتعاملكم معنا';
  static const establishmentName = 'المؤسسة التجارية للمبيعات';
  static const establishmentPhone = 'هاتف: 01000000000';
  static const establishmentAddress = 'العنوان: القاهرة - جمهورية مصر العربية';

  // تحديثات النظام (System Updates)
  static const systemUpdates = 'تحديثات النظام';
  static const updateAvailableTitle = 'تحديث جديد متاح!';
  static const currentVersion = 'الإصدار الحالي';
  static const newVersion = 'الإصدار الجديد';
  static const releaseNotes = 'ما الجديد في هذا التحديث:';
  static const downloadingUpdate = 'جاري تنزيل التحديث...';
  static const updateReadyToInstall = 'اكتمل التنزيل! التطبيق جاهز للتثبيت وإعادة التشغيل.';
  static const downloadUpdate = 'تنزيل التحديث';
  static const installNow = 'تثبيت التحديث الآن';
  static const later = 'لاحقاً';
  static const checkForUpdates = 'التحقق من وجود تحديثات';
  static const checkingForUpdates = 'جاري البحث عن تحديثات...';
  static const appUpToDate = 'أنت تستخدم أحدث إصدار بالفعل.';
  static const updateRequiredNotice = 'هذا التحديث إلزامي لمواصلة استخدام النظام.';
  static const updateDownloadFailed = 'فشل تنزيل ملف التحديث';
  static const updateInstallFailed = 'فشل تشغيل مثبت التحديث';
}
