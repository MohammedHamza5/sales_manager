enum UserRole {
  admin,
  cashier,
  accountant,
  stockManager;

  String get arabicLabel => switch (this) {
        UserRole.admin => 'مدير النظام',
        UserRole.cashier => 'كاشير / نقطة بيع',
        UserRole.accountant => 'محاسب مالي',
        UserRole.stockManager => 'أمين مخزن',
      };

  String get description => switch (this) {
        UserRole.admin => 'صلاحيات كاملة وغير مقيدة على كافة أقسام وإعدادات النظام',
        UserRole.cashier => 'إنشاء فواتير البيع والمرتجعات دون الاطلاع على الأرباح أو تكاليف الشراء',
        UserRole.accountant => 'إدارة الخزينة والمصروفات وحسابات العملاء والموردين والتقارير المالية',
        UserRole.stockManager => 'إدارة المخزون وفواتير المشتريات وتعديل الكميات والجرد الدوري',
      };

  bool hasPermission(AppPermission permission) {
    if (this == UserRole.admin) return true;

    return switch (this) {
      UserRole.admin => true,
      UserRole.cashier => switch (permission) {
          AppPermission.createSale => true,
          AppPermission.createReturn => true,
          AppPermission.manageCustomers => true,
          _ => false,
        },
      UserRole.accountant => switch (permission) {
          AppPermission.viewReports => true,
          AppPermission.viewProfits => true,
          AppPermission.viewCosts => true,
          AppPermission.manageExpenses => true,
          AppPermission.manageCashbox => true,
          AppPermission.manageCustomers => true,
          AppPermission.manageSuppliers => true,
          _ => false,
        },
      UserRole.stockManager => switch (permission) {
          AppPermission.manageProducts => true,
          AppPermission.managePurchases => true,
          AppPermission.manageSuppliers => true,
          AppPermission.manageInventory => true,
          AppPermission.viewCosts => true,
          _ => false,
        },
    };
  }
}

enum AppPermission {
  createSale,
  cancelSale,
  createReturn,
  viewReports,
  viewProfits,
  viewCosts,
  manageProducts,
  managePurchases,
  manageSuppliers,
  manageCustomers,
  manageInventory,
  manageCashbox,
  manageExpenses,
  manageUsers,
  viewAuditLog,
  manageSettings;

  String get arabicLabel => switch (this) {
        AppPermission.createSale => 'إنشاء فواتير البيع',
        AppPermission.cancelSale => 'إلغاء فواتير البيع',
        AppPermission.createReturn => 'تسجيل مرتجعات العملاء',
        AppPermission.viewReports => 'الاطلاع على التقارير المالية',
        AppPermission.viewProfits => 'الاطلاع على صافي الأرباح',
        AppPermission.viewCosts => 'رؤية أسعار الشراء وتكلفة المنتجات',
        AppPermission.manageProducts => 'إدارة وتعديل المنتجات والأسعار',
        AppPermission.managePurchases => 'تسجيل فواتير المشتريات',
        AppPermission.manageSuppliers => 'إدارة حسابات الموردين',
        AppPermission.manageCustomers => 'إدارة حسابات العملاء',
        AppPermission.manageInventory => 'الجرد وتسويات المخزون',
        AppPermission.manageCashbox => 'إدارة حركات الخزينة والنقدية',
        AppPermission.manageExpenses => 'تسجيل المصروفات العامة',
        AppPermission.manageUsers => 'إدارة المستخدمين وتوزيع الصلاحيات',
        AppPermission.viewAuditLog => 'الاطلاع على سجل الرقابة والعمليات',
        AppPermission.manageSettings => 'إعدادات النظام والنسخ الاحتياطي',
      };
}
