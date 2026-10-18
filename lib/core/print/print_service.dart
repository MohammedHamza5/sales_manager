import 'package:printing/printing.dart';
import 'templates/a4_invoice_template.dart';
import 'templates/statement_template.dart';
import 'templates/thermal_receipt_template.dart';

class PrintService {
  const PrintService();

  /// Prints a thermal receipt (80mm) for cashier sale
  Future<void> printSaleReceipt({
    required String invoiceNo,
    required DateTime date,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required String totalAmount,
    required String paidAmount,
    required String remainingAmount,
    String? note,
  }) async {
    final pdfBytes = await ThermalReceiptTemplate.generate(
      invoiceNo: invoiceNo,
      date: date,
      partyName: customerName,
      items: items,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      note: note,
    );

    await Printing.layoutPdf(
      name: 'receipt_$invoiceNo.pdf',
      onLayout: (format) async => pdfBytes,
    );
  }

  /// Prints a standard A4 invoice for sales
  Future<void> printSaleInvoice({
    required String invoiceNo,
    required DateTime date,
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    required List<Map<String, dynamic>> items,
    required String totalAmount,
    required String paidAmount,
    required String remainingAmount,
    String? note,
  }) async {
    final pdfBytes = await A4InvoiceTemplate.generate(
      title: 'فاتورة مبيعات',
      invoiceNo: invoiceNo,
      date: date,
      partyName: customerName,
      partyPhone: customerPhone,
      partyAddress: customerAddress,
      items: items,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      note: note,
    );

    await Printing.layoutPdf(
      name: 'sale_invoice_$invoiceNo.pdf',
      onLayout: (format) async => pdfBytes,
    );
  }

  /// Prints a standard A4 invoice for purchases
  Future<void> printPurchaseInvoice({
    required String invoiceNo,
    required DateTime date,
    required String supplierName,
    String? supplierPhone,
    String? supplierAddress,
    required List<Map<String, dynamic>> items,
    required String totalAmount,
    required String paidAmount,
    required String remainingAmount,
    String? note,
  }) async {
    final pdfBytes = await A4InvoiceTemplate.generate(
      title: 'فاتورة مشتريات',
      invoiceNo: invoiceNo,
      date: date,
      partyName: supplierName,
      partyPhone: supplierPhone,
      partyAddress: supplierAddress,
      items: items,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      note: note,
    );

    await Printing.layoutPdf(
      name: 'purchase_invoice_$invoiceNo.pdf',
      onLayout: (format) async => pdfBytes,
    );
  }

  /// Prints an account statement for customer or supplier
  Future<void> printAccountStatement({
    required String title,
    required String partyName,
    String? partyPhone,
    required String currentBalance,
    required List<Map<String, dynamic>> entries,
  }) async {
    final pdfBytes = await StatementTemplate.generate(
      title: title,
      partyName: partyName,
      partyPhone: partyPhone,
      currentBalance: currentBalance,
      entries: entries,
    );

    await Printing.layoutPdf(
      name: 'statement_${partyName.replaceAll(' ', '_')}.pdf',
      onLayout: (format) async => pdfBytes,
    );
  }
}
