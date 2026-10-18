import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../strings/app_strings.dart';

class ThermalReceiptTemplate {
  static Future<Uint8List> generate({
    required String invoiceNo,
    required DateTime date,
    required String partyName,
    required List<Map<String, dynamic>> items,
    required String totalAmount,
    required String paidAmount,
    required String remainingAmount,
    String? note,
  }) async {
    final pdf = pw.Document();

    pw.Font? fontRegular;
    pw.Font? fontBold;
    try {
      fontRegular = await PdfGoogleFonts.cairoRegular();
      fontBold = await PdfGoogleFonts.cairoBold();
    } catch (_) {
      // Fallback if offline
    }

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    // 80mm thermal paper width is approximately 72mm printable (204 points width)
    const rollWidth = 72 * PdfPageFormat.mm;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(rollWidth, double.infinity, marginAll: 4 * PdfPageFormat.mm),
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  AppStrings.establishmentName,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  AppStrings.establishmentPhone,
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  AppStrings.establishmentAddress,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // Metadata
              _buildRow('رقم الفاتورة:', invoiceNo),
              _buildRow('التاريخ:', DateFormat('yyyy/MM/dd HH:mm').format(date)),
              _buildRow('العميل / الطرف:', partyName),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // Items Table Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('الصنف', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('الكمية', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text('السعر', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text('الإجمالي', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.left)),
                ],
              ),
              pw.Divider(thickness: 0.5),

              // Items
              ...items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          item['name']?.toString() ?? '',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          item['quantity']?.toString() ?? '',
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item['price']?.toString() ?? '',
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item['total']?.toString() ?? '',
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // Totals
              _buildRow('الإجمالي:', '$totalAmount ج.م', isBold: true),
              _buildRow('المدفوع:', '$paidAmount ج.م'),
              _buildRow('المتبقي:', '$remainingAmount ج.م', isBold: true),

              if (note != null && note.isNotEmpty) ...[
                pw.Divider(thickness: 0.5),
                pw.Text('ملاحظات: $note', style: const pw.TextStyle(fontSize: 8)),
              ],

              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // Footer
              pw.Center(
                child: pw.Text(
                  AppStrings.thankYou,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
