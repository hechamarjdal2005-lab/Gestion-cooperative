import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart' as intl;
import 'package:http/http.dart' as http;
import '../../shared/models/document.dart';
import '../../shared/models/cooperative.dart';
import '../../core/utils/amount_to_words.dart';

class PdfService {
  static final _primaryColor = PdfColor.fromHex('1B3A6B');
  static final _accentColor  = PdfColor.fromHex('E87722');
  static final _lightBlue    = PdfColor.fromHex('EEF4FF');
  static final _tableBg      = PdfColor.fromHex('F5F7FA');
  static final _borderColor  = PdfColor.fromHex('E0E0E0');

  Future<pw.Document> generateDocumentPdf({
    required AppDocument document,
    required Cooperative cooperative,
    required List<DocumentItem> items,
    required bool isArabic,
    String? logoBytes,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.amiriRegular();
    final fontBold = await PdfGoogleFonts.amiriBold();

    pw.MemoryImage? logoImage;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      try {
        final bytes = base64Decode(logoBytes);
        logoImage = pw.MemoryImage(bytes);
      } catch (_) {
      }
    }

    final textDirection = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        textDirection: textDirection,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        header: (context) => _buildHeader(cooperative, document, isArabic, logoImage),
        footer: (context) => _buildFooter(cooperative, isArabic),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.SizedBox(height: 10),
            _buildClientSection(document, isArabic),
            pw.SizedBox(height: 15),
            _buildItemsTable(items, document.type, isArabic),
            pw.SizedBox(height: 15),
          ];

          if (document.type != 'BDL') {
            widgets.add(_buildTotals(document, items, isArabic));
            widgets.add(pw.SizedBox(height: 10));
            widgets.add(_buildAmountInWords(document, items, isArabic));
            widgets.add(pw.SizedBox(height: 15));
          }

          widgets.add(_buildSignatures(document, isArabic));

          if (document.additionalInfo != null && document.additionalInfo!.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 10));
            widgets.add(_buildAdditionalInfo(document, isArabic));
          }

          return widgets;
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(Cooperative coop, AppDocument doc, bool isArabic, pw.MemoryImage? logoImage) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      image: pw.DecorationImage(image: logoImage, fit: pw.BoxFit.contain),
                    ),
                  ),
                if (logoImage != null) pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        coop.name,
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                      ),
                      pw.SizedBox(height: 3),
                      if (coop.address != null)
                        pw.Text(coop.address!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      if (coop.phone != null)
                        pw.Text(coop.phone!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      if (coop.email != null)
                        pw.Text(coop.email!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          if (coop.ice != null)
                            pw.Text('ICE: ${coop.ice}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                          if (coop.rc != null) ...[
                            pw.SizedBox(width: 15),
                            pw.Text('RC: ${coop.rc}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _primaryColor,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    doc.typeLabel,
                    style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  doc.number,
                  style: pw.TextStyle(fontSize: 12, color: _primaryColor, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  intl.DateFormat('dd/MM/yyyy').format(doc.date),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClientSection(AppDocument doc, bool isArabic) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _lightBlue,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: _primaryColor,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              isArabic ? 'الزبون' : 'CLIENT',
              style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  doc.clientName ?? '',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                ),
                pw.SizedBox(height: 2),
                if (doc.clientAddress != null && doc.clientAddress!.isNotEmpty)
                  pw.Text(doc.clientAddress!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (doc.clientPhone != null && doc.clientPhone!.isNotEmpty)
                  pw.Text(doc.clientPhone!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (doc.type == 'BDL' && doc.deliveryLocation != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    isArabic ? 'مكان التسليم: ${doc.deliveryLocation}' : 'Lieu: ${doc.deliveryLocation}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
                if (doc.type == 'BDC' && doc.deliveryDelay != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    isArabic ? 'مدة التسليم: ${doc.deliveryDelay}' : 'Délai: ${doc.deliveryDelay}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(List<DocumentItem> items, String docType, bool isArabic) {
    final bool showPrices = docType != 'BDL';

    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: _primaryColor, width: 1),
        bottom: pw.BorderSide(color: _primaryColor, width: 1),
        left: pw.BorderSide(color: _borderColor, width: 0.5),
        right: pw.BorderSide(color: _borderColor, width: 0.5),
        verticalInside: pw.BorderSide(color: _borderColor, width: 0.5),
        horizontalInside: pw.BorderSide(color: _borderColor, width: 0.5),
      ),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primaryColor),
          children: _buildHeaderCells(showPrices, isArabic),
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index % 2 == 0 ? PdfColors.white : _tableBg,
            ),
            children: _buildItemCells(item, showPrices, isArabic),
          );
        }),
      ],
    );
  }

  List<pw.Widget> _buildHeaderCells(bool showPrices, bool isArabic) {
    final style = const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white);

    if (isArabic) {
      return [
        if (showPrices) ...[
          _headerCell(isArabic ? 'المجموع' : 'Total', style),
          _headerCell(isArabic ? 'الثمن الوحدوي' : 'P.U', style),
        ],
        _headerCell(isArabic ? 'الوحدة' : 'Unité', style),
        _headerCell(isArabic ? 'الكمية' : 'Qté', style),
        _headerCell(isArabic ? 'الوصف' : 'Description', style),
        _headerCell(isArabic ? 'المرجع' : 'Réf.', style),
      ];
    } else {
      return [
        _headerCell('Réf.', style),
        _headerCell('Description', style),
        _headerCell('Qté', style),
        _headerCell('Unité', style),
        if (showPrices) ...[
          _headerCell('P.U', style),
          _headerCell('Total', style),
        ],
      ];
    }
  }

  pw.Widget _headerCell(String text, pw.TextStyle style) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      alignment: pw.Alignment.center,
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  List<pw.Widget> _buildItemCells(DocumentItem item, bool showPrices, bool isArabic) {
    final style = const pw.TextStyle(fontSize: 8);
    final numberStyle = const pw.TextStyle(fontSize: 8, color: PdfColors.grey800);

    if (isArabic) {
      return [
        if (showPrices)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(item.total.toStringAsFixed(2), style: numberStyle, textAlign: pw.TextAlign.center),
          ),
        if (showPrices)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(item.unitPrice.toStringAsFixed(2), style: numberStyle, textAlign: pw.TextAlign.center),
          ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(item.unit, style: style, textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(item.quantity.toString(), style: style, textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(item.description.isNotEmpty ? item.description : (item.productName ?? ''), style: style),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(item.productRef, style: numberStyle, textAlign: pw.TextAlign.center),
        ),
      ];
    } else {
      return [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(item.productRef, style: numberStyle, textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(item.description.isNotEmpty ? item.description : (item.productName ?? ''), style: style),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(item.quantity.toString(), style: style, textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(item.unit, style: style, textAlign: pw.TextAlign.center),
        ),
        if (showPrices)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(item.unitPrice.toStringAsFixed(2), style: numberStyle, textAlign: pw.TextAlign.center),
          ),
        if (showPrices)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(item.total.toStringAsFixed(2), style: numberStyle, textAlign: pw.TextAlign.center),
          ),
      ];
    }
  }

  pw.Widget _buildTotals(AppDocument doc, List<DocumentItem> items, bool isArabic) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final discountAmount = subtotal * (doc.discount / 100);
    final afterDiscount = subtotal - discountAmount;
    final tvaAmount = afterDiscount * (doc.tvaRate / 100);
    final total = afterDiscount + tvaAmount + doc.deliveryFees;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          _totalRow(isArabic ? 'المجموع الصافي' : 'Sous-total', '${subtotal.toStringAsFixed(2)} DH', isArabic),
          if (doc.discount > 0)
            _totalRow(
              isArabic ? 'الخصم (${doc.discount}%)' : 'Remise (${doc.discount}%)',
              '-${discountAmount.toStringAsFixed(2)} DH',
              isArabic,
              isNegative: true,
            ),
          if (doc.tvaRate > 0)
            _totalRow(
              isArabic ? 'الضريبة (${doc.tvaRate}%)' : 'TVA (${doc.tvaRate}%)',
              '${tvaAmount.toStringAsFixed(2)} DH',
              isArabic,
            ),
          if (doc.deliveryFees > 0)
            _totalRow(
              isArabic ? 'مصاريف التسليم' : 'Frais de livraison',
              '${doc.deliveryFees.toStringAsFixed(2)} DH',
              isArabic,
            ),
          pw.Divider(height: 1, thickness: 1.5, color: _borderColor),
          _totalRow(
            isArabic ? 'المجموع النهائي' : 'TOTAL À PAYER',
            '${total.toStringAsFixed(2)} DH',
            isArabic,
            isBold: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _totalRow(
    String label,
    String value,
    bool isArabic, {
    bool isBold = false,
    bool isNegative = false,
    bool isTotal = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: isTotal ? pw.BoxDecoration(color: PdfColor(0.91, 0.47, 0.13, 0.1)) : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 10 : 9,
              fontWeight: isBold ? pw.FontWeight.bold : null,
              color: isTotal ? _accentColor : null,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 10 : 9,
              fontWeight: isBold ? pw.FontWeight.bold : null,
              color: isNegative ? PdfColors.red : (isTotal ? _accentColor : null),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAmountInWords(AppDocument doc, List<DocumentItem> items, bool isArabic) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final discountAmount = subtotal * (doc.discount / 100);
    final afterDiscount = subtotal - discountAmount;
    final tvaAmount = afterDiscount * (doc.tvaRate / 100);
    final total = afterDiscount + tvaAmount + doc.deliveryFees;

    final amountWords = AmountToWords.withCurrency(total);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _lightBlue,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            isArabic ? 'المبلغ بالحروف: ' : 'Arrêté la présente facture à la somme de : ',
            style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
          ),
          pw.Expanded(
            child: pw.Text(
              amountWords,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatures(AppDocument doc, bool isArabic) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _signatureBlock(
          title: isArabic ? 'توقيع الزبون' : 'Signature Client',
          subtitle: isArabic ? (doc.type == 'BDL' ? 'استلم في:' : 'موافقة:') : (doc.type == 'BDL' ? 'Reçu le:' : 'Bon pour:'),
          isArabic: isArabic,
        ),
        pw.Spacer(),
        _signatureBlock(
          title: isArabic ? 'توقيع المورد' : 'Signature Fournisseur',
          subtitle: isArabic ? (doc.type == 'BDL' ? 'سلم في:' : 'الختم:') : (doc.type == 'BDL' ? 'Livré le:' : 'Cachet:'),
          isArabic: isArabic,
          showStamp: true,
        ),
      ],
    );
  }

  pw.Widget _signatureBlock({
    required String title,
    required String subtitle,
    required bool isArabic,
    bool showStamp = false,
  }) {
    return pw.SizedBox(
      width: 150,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryColor),
          ),
          pw.SizedBox(height: 4),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 40),
          pw.Container(
            width: double.infinity,
            height: 0.5,
            color: PdfColors.grey400,
          ),
          if (showStamp) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              isArabic ? 'الختم' : 'Cachet',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildAdditionalInfo(AppDocument doc, bool isArabic) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? 'معلومات إضافية:' : 'Informations:',
            style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            doc.additionalInfo!,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(Cooperative coop, bool isArabic) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            '${coop.address ?? ''} | ${coop.phone ?? ''} | ${coop.email ?? ''}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
        ],
      ),
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

  Future<String?> fetchLogoAsBase64(String? logoUrl) async {
    if (logoUrl == null || logoUrl.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(logoUrl));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
    } catch (_) {
    }
    return null;
  }
}
