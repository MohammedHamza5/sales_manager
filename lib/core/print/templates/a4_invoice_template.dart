import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../strings/app_strings.dart';

class A4InvoiceTemplate {
  static Future<Uint8List> generate({
    required String title,
    required String invoiceNo,
    required DateTime date,
    required String partyName,
    String? partyPhone,
    String? partyAddress,
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
      // Fallback
    }

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return [
            // Header Banner
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      AppStrings.establishmentName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      AppStrings.establishmentPhone,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      AppStrings.establishmentAddress,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
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
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'رقم: #$invoiceNo',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.Text(
                        'التاريخ: ${DateFormat('yyyy/MM/dd HH:mm').format(date)}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Party Info Card
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
                      pw.Text(
                        'العميل / الطرف المتعامل:',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        partyName,
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  if (partyPhone != null && partyPhone.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'رقم الهاتف:',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                        pw.Text(partyPhone, style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  if (partyAddress != null && partyAddress.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'العنوان:',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                        pw.Text(partyAddress, style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(4),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1),
                4: pw.FlexColumnWidth(2),
                5: pw.FlexColumnWidth(2),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildCell('#', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('اسم الصنف / البيان', isHeader: true),
                    _buildCell('الكمية', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('الوحدة', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('سعر الوحدة', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('الإجمالي', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                // Rows
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _buildCell('$idx', align: pw.TextAlign.center),
                      _buildCell(item['name']?.toString() ?? ''),
                      _buildCell(item['quantity']?.toString() ?? '', align: pw.TextAlign.center),
                      _buildCell(item['unit']?.toString() ?? 'قطعة', align: pw.TextAlign.center),
                      _buildCell('${item['price']} ج.م', align: pw.TextAlign.center),
                      _buildCell('${item['total']} ج.م', align: pw.TextAlign.center),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // Bottom Section: Notes & Totals Card
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Notes
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ملاحظات وشروط الفاتورة:',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          note?.isNotEmpty == true
                              ? note!
                              : 'البضاعة المباعة لا تُرد ولا تُستبدل إلا بموجب أصل الفاتورة وخلال المدة القانونية.',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 24),

                // Financial Summary
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      children: [
                        _buildTotalRow('إجمالي الفاتورة:', '$totalAmount ج.م', isBold: true),
                        pw.Divider(color: PdfColors.grey300),
                        _buildTotalRow('المبلغ المدفوع:', '$paidAmount ج.م'),
                        pw.Divider(color: PdfColors.grey300),
                        _buildTotalRow(
                          'المبلغ المتبقي:',
                          '$remainingAmount ج.م',
                          isBold: true,
                          color: PdfColors.red900,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 36),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('توقيع المستلم', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 28),
                    pw.Text('................................', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('ختم المنشأة / توقيع المسؤول', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 28),
                    pw.Text('................................', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.start,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}
