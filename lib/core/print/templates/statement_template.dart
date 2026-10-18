import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../strings/app_strings.dart';

class StatementTemplate {
  static Future<Uint8List> generate({
    required String title,
    required String partyName,
    String? partyPhone,
    required String currentBalance,
    required List<Map<String, dynamic>> entries,
  }) async {
    final pdf = pw.Document();

    pw.Font? fontRegular;
    pw.Font? fontBold;
    try {
      fontRegular = await PdfGoogleFonts.cairoRegular();
      fontBold = await PdfGoogleFonts.cairoBold();
    } catch (_) {}

    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      AppStrings.establishmentName,
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(AppStrings.establishmentPhone, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.blue300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('تاريخ الطباعة: ${DateFormat('yyyy/MM/dd').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Party & Balance Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('الاسم / الحساب:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(partyName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      if (partyPhone != null) pw.Text('هاتف: $partyPhone', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('الرصيد الحالي:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(
                        '$currentBalance ج.م',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Ledger Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(3),
                3: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(2),
                5: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _cell('التاريخ', isHeader: true, align: pw.TextAlign.center),
                    _cell('نوع الحركة', isHeader: true, align: pw.TextAlign.center),
                    _cell('البيان / ملاحظات', isHeader: true),
                    _cell('مدين (+)', isHeader: true, align: pw.TextAlign.center),
                    _cell('دائن (-)', isHeader: true, align: pw.TextAlign.center),
                    _cell('الرصيد بعد', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                ...entries.map((entry) {
                  return pw.TableRow(
                    children: [
                      _cell(entry['date']?.toString() ?? '', align: pw.TextAlign.center),
                      _cell(entry['type']?.toString() ?? '', align: pw.TextAlign.center),
                      _cell(entry['note']?.toString() ?? '—'),
                      _cell(entry['debit'] != null ? '${entry['debit']} ج.م' : '—', align: pw.TextAlign.center),
                      _cell(entry['credit'] != null ? '${entry['credit']} ج.م' : '—', align: pw.TextAlign.center),
                      _cell('${entry['balanceAfter']} ج.م', align: pw.TextAlign.center),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.start}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
