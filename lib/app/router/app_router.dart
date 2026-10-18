import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'desktop_sidebar.dart';
import '../../core/theme/app_colors.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/suppliers/presentation/pages/suppliers_page.dart';
import '../../features/opening_balance/presentation/pages/opening_balance_page.dart';
import '../../features/purchases/presentation/pages/purchases_list_page.dart';
import '../../features/purchases/presentation/pages/create_purchase_page.dart';
import '../../features/purchases/presentation/pages/purchase_detail_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/sales/presentation/pages/sales_list_page.dart';
import '../../features/sales/presentation/pages/create_sale_page.dart';
import '../../features/sales/presentation/pages/sale_detail_page.dart';
import '../../features/returns/presentation/pages/returns_page.dart';
import '../../features/cashbox/presentation/pages/cashbox_page.dart';
import '../../features/expenses/presentation/pages/expenses_page.dart';
import '../../features/customer_payments/presentation/pages/customer_payments_page.dart';
import '../../features/supplier_payments/presentation/pages/supplier_payments_page.dart';
import '../../features/reports/presentation/cubit/reports_cubit.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../core/di/injector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/shortcuts/app_shortcuts.dart';
import '../../core/shortcuts/universal_search_dialog.dart';
import '../../core/widgets/app_title_bar.dart';
import '../../features/update/presentation/cubit/update_cubit.dart';
import '../../features/update/presentation/cubit/update_state.dart';
import '../../features/update/presentation/dialogs/update_dialog.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainDesktopShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider<DashboardCubit>(
            create: (_) => getIt<DashboardCubit>(),
            child: const DashboardPage(),
          ),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductsPage(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryPage(),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomersPage(),
        ),
        GoRoute(
          path: '/suppliers',
          builder: (context, state) => const SuppliersPage(),
        ),
        GoRoute(
          path: '/sales',
          builder: (context, state) => const SalesListPage(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const CreateSalePage(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return SaleDetailPage(id: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/purchases',
          builder: (context, state) => const PurchasesListPage(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) {
                final supplierIdStr = state.uri.queryParameters['supplierId'];
                final supplierId =
                    supplierIdStr != null ? int.tryParse(supplierIdStr) : null;
                final supplierName = state.uri.queryParameters['supplierName'];
                return CreatePurchasePage(
                  preselectedSupplierId: supplierId,
                  preselectedSupplierName: supplierName,
                );
              },
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return PurchaseDetailPage(id: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/returns',
          builder: (context, state) => const ReturnsPage(),
        ),
        GoRoute(
          path: '/cashbox',
          builder: (context, state) => const CashboxPage(),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const ExpensesPage(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<ReportsCubit>(),
            child: const ReportsPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
          routes: [
            GoRoute(
              path: 'backup',
              builder: (context, state) => const SettingsPage(initialTabIndex: 0),
            ),
            GoRoute(
              path: 'audit-log',
              builder: (context, state) => const SettingsPage(initialTabIndex: 1),
            ),
          ],
        ),
        GoRoute(
          path: '/opening-balance',
          builder: (context, state) => const OpeningBalancePage(),
        ),
        GoRoute(
          path: '/payments/customers',
          builder: (context, state) {
            final idStr = state.uri.queryParameters['customerId'];
            final customerId = idStr != null ? int.tryParse(idStr) : null;
            return CustomerPaymentsPage(customerId: customerId);
          },
        ),
        GoRoute(
          path: '/customer-payments',
          builder: (context, state) {
            final idStr = state.uri.queryParameters['customerId'];
            final customerId = idStr != null ? int.tryParse(idStr) : null;
            return CustomerPaymentsPage(customerId: customerId);
          },
        ),
        GoRoute(
          path: '/supplier-payments',
          builder: (context, state) {
            final idStr = state.uri.queryParameters['supplierId'];
            final supplierId = idStr != null ? int.tryParse(idStr) : null;
            return SupplierPaymentsPage(supplierId: supplierId);
          },
        ),
        GoRoute(
          path: '/payments/suppliers',
          builder: (context, state) {
            final idStr = state.uri.queryParameters['supplierId'];
            final supplierId = idStr != null ? int.tryParse(idStr) : null;
            return SupplierPaymentsPage(supplierId: supplierId);
          },
        ),
      ],
    ),
  ],
);

class MainDesktopShell extends StatefulWidget {
  final Widget child;

  const MainDesktopShell({super.key, required this.child});

  @override
  State<MainDesktopShell> createState() => _MainDesktopShellState();
}

class _MainDesktopShellState extends State<MainDesktopShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UpdateCubit>().checkForUpdates(isManual: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final colors = context.colors;

    return BlocListener<UpdateCubit, UpdateState>(
      listenWhen: (previous, current) =>
          current.status == UpdateStatus.available &&
          previous.status != UpdateStatus.available,
      listener: (context, state) {
        showDialog<void>(
          context: context,
          barrierDismissible: !(state.updateInfo?.isRequired ?? false),
          builder: (ctx) => BlocProvider.value(
            value: context.read<UpdateCubit>(),
            child: const UpdateDialog(),
          ),
        );
      },
      child: CallbackShortcuts(
        bindings: {
          AppShortcuts.help: () => AppShortcuts.showHelpDialog(context),
          AppShortcuts.helpAlt: () => AppShortcuts.showHelpDialog(context),
          AppShortcuts.helpSlash: () => AppShortcuts.showHelpDialog(context),
          AppShortcuts.search: () => UniversalSearchDialog.show(context),
          AppShortcuts.searchAlt: () => UniversalSearchDialog.show(context),
          AppShortcuts.newSale: () => context.go('/sales/create'),
          AppShortcuts.newSaleAlt: () => context.go('/sales/create'),
          AppShortcuts.newPurchase: () => context.go('/purchases/create'),
          AppShortcuts.newPurchaseAlt: () => context.go('/purchases/create'),
          AppShortcuts.newPurchaseAlt2: () => context.go('/purchases/create'),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Column(
              children: [
                const AppTitleBar(),
                Expanded(
                  child: Row(
                    children: [
                      AppDesktopSidebar(currentLocation: location),
                      VerticalDivider(width: 1, thickness: 1, color: colors.border),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
