import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart' as intl;
import '../../shared/models/document.dart';
import '../../shared/models/cooperative.dart';

class PdfService {
  Future<pw.Document> generateDocumentPdf(
    AppDocument document,
    Cooperative cooperative,
    List<dynamic> items,
    bool isArabic,
  ) async {
    final pdf = pw.Document();
    
    // Load Arabic font if needed
    final font = await PdfGoogleFonts.amiriRegular();
    final fontBold = await PdfGoogleFonts.amiriBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(cooperative, document, isArabic),
            pw.SizedBox(height: 20),
            _buildInfo(document, isArabic),
            pw.SizedBox(height: 20),
            _buildTable(items, isArabic),
            pw.SizedBox(height: 20),
            _buildSummary(document, isArabic),
            pw.SizedBox(height: 40),
            _buildFooter(cooperative),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(Cooperative coop, AppDocument doc, bool isArabic) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(coop.name, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text(coop.address ?? ''),
            pw.Text(coop.phone ?? ''),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(doc.type, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Text(doc.number),
            pw.Text(intl.DateFormat('yyyy/MM/dd').format(doc.date)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInfo(AppDocument doc, bool isArabic) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(isArabic ? 'المرسل إليه:' : 'Client/Fournisseur:'),
          pw.Text(doc.clientName ?? doc.supplierName ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildTable(List<dynamic> items, bool isArabic) {
    final headers = isArabic 
      ? ['المجموع', 'الثمن الوحدوي', 'الكمية', 'المنتج']
      : ['Produit', 'Quantité', 'Prix Unitaire', 'Total'];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: items.map((item) => [
        item.total.toStringAsFixed(2),
        item.unitPrice.toStringAsFixed(2),
        item.quantity.toString(),
        item.productName,
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.center,
    );
  }

  pw.Widget _buildSummary(AppDocument doc, bool isArabic) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _summaryRow(isArabic ? 'المجموع الصافي:' : 'Total HT:', doc.total.toStringAsFixed(2)),
            _summaryRow(isArabic ? 'الضريبة (20%):' : 'TVA (20%):', (doc.total * 0.2).toStringAsFixed(2)),
            pw.Divider(),
            _summaryRow(isArabic ? 'المجموع النهائي:' : 'Total TTC:', (doc.total * 1.2).toStringAsFixed(2), isBold: true),
          ],
        ),
      ],
    );
  }

  pw.Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
          pw.SizedBox(width: 20),
          pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(Cooperative coop) {
    return pw.Align(
      alignment: pw.Alignment.center,
      child: pw.Text(coop.name, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
    );
  }

  Future<String> savePdfToDevice(pw.Document pdf, String fileName) async {
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<void> sharePdf(pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName.pdf');
    await tempFile.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(tempFile.path)],
      text: fileName,
    );
  }

  Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
