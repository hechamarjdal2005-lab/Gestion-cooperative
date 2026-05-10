import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart' as intl;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/document.dart';
import '../../shared/models/cooperative.dart';
import '../../core/utils/amount_to_words.dart';

class PdfService {
  static final _primaryColor = PdfColor.fromHex('1A2A4A');
  static final _accentColor  = PdfColor.fromHex('FF8C00');
  static final _tableHeaderBg = _primaryColor;
  static final _tableRowAlternateBg = PdfColor.fromHex('F9FAFB');
  static final _borderColor = PdfColor.fromHex('E5E7EB');

  Future<pw.Document> generateDocumentPdf({
    required AppDocument document,
    required Cooperative cooperative,
    required List<DocumentItem> items,
    bool isArabic = true,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.amiriRegular();
    final fontBold = await PdfGoogleFonts.amiriBold();

    pw.MemoryImage? logoImage;
    if (cooperative.logoUrl != null && cooperative.logoUrl!.isNotEmpty) {
      final logoBytes = await _fetchLogoBytes(cooperative.logoUrl!);
      if (logoBytes != null) logoImage = pw.MemoryImage(logoBytes);
    }

    if (document.type == 'DEV') {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          textDirection: pw.TextDirection.ltr,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (context) => [
            _buildDevisHeader(cooperative, logoImage),
            pw.SizedBox(height: 20),
            _buildDevisInfoSection(cooperative, document),
            pw.SizedBox(height: 20),
            _buildDevisDocInfo(document),
            pw.SizedBox(height: 20),
            _buildDevisItemsTable(items),
            pw.SizedBox(height: 20),
            _buildDevisTotals(document, items),
            pw.SizedBox(height: 40),
            _buildDevisFooter(cooperative),
          ],
        ),
      );
    } else {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          header: (context) => _buildHeader(cooperative, document, isArabic, logoImage),
          footer: (context) => _buildFooter(cooperative),
          build: (context) => [
            pw.SizedBox(height: 20),
            _buildInfoSection(document, isArabic),
            pw.SizedBox(height: 25),
            _buildItemsTable(items, document.type, isArabic),
            pw.SizedBox(height: 20),
            if (document.type == 'FAC' || document.type == 'BDC') ...[
              _buildTotalsSection(document, items, isArabic),
            ] else if (document.type == 'BDL') ...[
              _buildDeliverySpecifics(document, isArabic),
            ],
            pw.SizedBox(height: 30),
            _buildSignatures(document, isArabic),
          ],
        ),
      );
    }
    return pdf;
  }

  pw.Widget _buildDevisHeader(Cooperative coop, pw.MemoryImage? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (logo != null) pw.Container(width: 80, height: 80, child: pw.Image(logo))
        else pw.Container(width: 80, height: 80, color: PdfColors.grey300),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('DEVIS', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
            pw.Container(height: 2, width: 100, color: _primaryColor),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDevisInfoSection(Cooperative coop, AppDocument doc) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(coop.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(coop.address ?? '', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(coop.phone ?? '', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(coop.email ?? '', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('À L\'ATTENTION DE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(doc.clientName ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(doc.clientAddress ?? '', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(doc.clientPhone ?? '', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDevisDocInfo(AppDocument doc) {
    return pw.Row(
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Date : ${intl.DateFormat('dd/MM/yyyy', 'en_US').format(doc.date)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Devis n° : ${doc.number}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDevisItemsTable(List<DocumentItem> items) {
    return pw.TableHelper.fromTextArray(
      headers: ['DESCRIPTION', 'PRIX UNITAIRE', 'QUANTITÉ', 'TOTAL'],
      data: items.map((i) => [
        i.description,
        '${intl.NumberFormat('#,##0.00', 'en_US').format(i.unitPrice)} DH',
        i.quantity.toString(),
        '${intl.NumberFormat('#,##0.00', 'en_US').format(i.total)} DH'
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: _primaryColor),
      cellAlignment: pw.Alignment.center,
      cellStyle: const pw.TextStyle(fontSize: 10),
      columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1)},
    );
  }

  pw.Widget _buildDevisTotals(AppDocument doc, List<DocumentItem> items) {
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.total);
    final discount = subtotal * (doc.discount / 100);
    final tva = (subtotal - discount) * (doc.tvaRate / 100);
    final total = (subtotal - discount) + tva + doc.deliveryFees;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          child: pw.Column(
            children: [
              _devisTotalRow('Sous total :', '${intl.NumberFormat('#,##0.00', 'en_US').format(subtotal)} DH'),
              if (doc.discount > 0) _devisTotalRow('Remise (${doc.discount}%) :', '-${intl.NumberFormat('#,##0.00', 'en_US').format(discount)} DH'),
              _devisTotalRow('TVA (${doc.tvaRate.toStringAsFixed(0)}%) :', '${intl.NumberFormat('#,##0.00', 'en_US').format(tva)} DH'),
              if (doc.deliveryFees > 0) _devisTotalRow('Frais de livraison :', '${intl.NumberFormat('#,##0.00', 'en_US').format(doc.deliveryFees)} DH'),
              pw.Divider(),
              _devisTotalRow('TOTAL :', '${intl.NumberFormat('#,##0.00', 'en_US').format(total)} DH', isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _devisTotalRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }

  pw.Widget _buildDevisFooter(Cooperative coop) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Signature suivie de la mention', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('«bon pour accord»', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 50),
                pw.Container(width: 150, height: 1, color: PdfColors.grey),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.Text('${coop.phone ?? ""} | ${coop.email ?? ""} | ${coop.address ?? ""}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    );
  }

  Future<pw.Document> generateFinancialReportPdf({
    required DateTime startDate,
    required DateTime endDate,
    required List<dynamic> incomes,
    required List<dynamic> expenses,
    required Cooperative cooperative,
    bool isArabic = true,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.amiriRegular();
    final fontBold = await PdfGoogleFonts.amiriBold();

    pw.MemoryImage? logoImage;
    if (cooperative.logoUrl != null && cooperative.logoUrl!.isNotEmpty) {
      final logoBytes = await _fetchLogoBytes(cooperative.logoUrl!);
      if (logoBytes != null) logoImage = pw.MemoryImage(logoBytes);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logoImage != null) pw.Container(width: 60, height: 60, child: pw.Image(logoImage)),
              pw.Column(
                crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(isArabic ? 'التقرير المالي' : 'Rapport Financier', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
                  pw.Text(
                    isArabic 
                      ? 'الفترة : من ${intl.DateFormat('dd/MM/yyyy', 'en_US').format(startDate)} إلى ${intl.DateFormat('dd/MM/yyyy', 'en_US').format(endDate)}'
                      : 'Période : ${intl.DateFormat('dd/MM/yyyy', 'en_US').format(startDate)} au ${intl.DateFormat('dd/MM/yyyy', 'en_US').format(endDate)}', 
                    style: const pw.TextStyle(fontSize: 10)
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text(isArabic ? 'المداخيل (Revenus)' : 'Revenus', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
          pw.SizedBox(height: 10),
          _buildFinancialTable(
            headers: isArabic ? ['التاريخ', 'الفئة', 'تفاصيل', 'المبلغ (درهم)'] : ['Date', 'Catégorie', 'Détails', 'Montant (DH)'],
            data: incomes.map((i) => [intl.DateFormat('dd/MM/yyyy', 'en_US').format(i.date), i.category.toString(), (i.note ?? '').toString(), intl.NumberFormat('#,##0.00', 'en_US').format(i.amount)].cast<String>()).toList(),
            isArabic: isArabic,
          ),
          pw.SizedBox(height: 20),
          pw.Text(isArabic ? 'المصاريف (Dépenses)' : 'Dépenses', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
          pw.SizedBox(height: 10),
          _buildFinancialTable(
            headers: isArabic ? ['التاريخ', 'الفئة', 'المبلغ (درهم)'] : ['Date', 'Catégorie', 'Montant (DH)'],
            data: expenses.map((e) => <String>[intl.DateFormat('dd/MM/yyyy', 'en_US').format(e.date), e.category, intl.NumberFormat('#,##0.00', 'en_US').format(e.amount)]).toList(),
            isArabic: isArabic,
          ),
          pw.SizedBox(height: 30),
          _buildFinancialSummary(incomes, expenses, isArabic),
        ],
      ),
    );
    return pdf;
  }

  pw.Widget _buildFinancialTable({required List<String> headers, required List<List<String>> data, bool isArabic = false}) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: pw.BoxDecoration(color: _primaryColor),
      cellAlignment: pw.Alignment.center,
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      tableDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
    );
  }

  pw.Widget _buildFinancialSummary(List<dynamic> incomes, List<dynamic> expenses, bool isArabic) {
    final totalIncomes = incomes.fold<double>(0, (sum, i) => sum + i.amount);
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final netBalance = totalIncomes - totalExpenses;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: PdfColors.grey300)),
      child: pw.Column(
        children: [
          _summaryRow(isArabic ? 'إجمالي المداخيل :' : 'Total Revenus :', '${intl.NumberFormat('#,##0.00', 'en_US').format(totalIncomes)} DH', isArabic: isArabic),
          _summaryRow(isArabic ? 'إجمالي المصاريف :' : 'Total Dépenses :', '${intl.NumberFormat('#,##0.00', 'en_US').format(totalExpenses)} DH', isArabic: isArabic),
          pw.Divider(),
          _summaryRow(isArabic ? 'الرصيد الصافي :' : 'Solde Net :', '${intl.NumberFormat('#,##0.00', 'en_US').format(netBalance)} DH', isBold: true, color: netBalance >= 0 ? PdfColors.green : PdfColors.red, isArabic: isArabic),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(String label, String value, {bool isBold = false, PdfColor? color, bool isArabic = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : null)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : null, color: color)),
        ],
      ),
    );
  }

  pw.Widget _buildHeader(Cooperative coop, AppDocument doc, bool isArabic, pw.MemoryImage? logoImage) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(coop.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
                pw.SizedBox(height: 4),
                _headerInfoText(coop.address ?? ''),
                _headerInfoText(coop.phone ?? ''),
                _headerInfoText(coop.email ?? ''),
                pw.SizedBox(height: 4),
                pw.Row(children: [if (coop.rc != null) _headerInfoText('RC: ${coop.rc}  '), if (coop.ice != null) _headerInfoText('ICE: ${coop.ice}')]),
              ],
            ),
            if (logoImage != null) pw.Container(width: 70, height: 70, child: pw.Image(logoImage, fit: pw.BoxFit.contain))
            else pw.Container(width: 70, height: 70, decoration: pw.BoxDecoration(color: _primaryColor, borderRadius: pw.BorderRadius.circular(8)), alignment: pw.Alignment.center, child: pw.Text(coop.name.isNotEmpty ? coop.name.substring(0, 1).toUpperCase() : 'C', style: pw.TextStyle(fontSize: 30, color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Divider(color: _borderColor, thickness: 1),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(doc.typeLabel, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _primaryColor)), pw.Text(doc.number, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _accentColor))]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text(isArabic ? 'التاريخ:' : 'Date:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)), pw.Text(intl.DateFormat('dd/MM/yyyy', 'en_US').format(doc.date), style: const pw.TextStyle(fontSize: 11))]),
          ],
        ),
      ],
    );
  }

  pw.Widget _headerInfoText(String text) {
    return pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700));
  }

  pw.Widget _buildInfoSection(AppDocument doc, bool isArabic) {
    final isSupplier = doc.type == 'BDC';
    final name = isSupplier ? (doc.supplierName ?? '') : (doc.clientName ?? '');
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderColor), borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(isSupplier ? (isArabic ? 'المورد:' : 'FOURNISSEUR:') : (isArabic ? 'الزبون:' : 'CLIENT:'), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
          pw.SizedBox(height: 5),
          pw.Text(name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (doc.clientPhone != null) _headerInfoText(doc.clientPhone!),
          if (doc.clientAddress != null) _headerInfoText(doc.clientAddress!),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(List<DocumentItem> items, String docType, bool isArabic) {
    final showPrices = docType != 'BDL';
    return pw.Table(
      border: pw.TableBorder(horizontalInside: pw.BorderSide(color: _borderColor, width: 0.5), bottom: pw.BorderSide(color: _primaryColor, width: 1)),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _tableHeaderBg),
          children: [
            if (showPrices) _tableHeaderCell(isArabic ? 'المجموع' : 'Total'),
            if (showPrices) _tableHeaderCell(isArabic ? 'الثمن الوحدوي' : 'P.U'),
            _tableHeaderCell(isArabic ? 'الوحدة' : 'Unité'),
            _tableHeaderCell(isArabic ? 'الكمية' : 'Qté'),
            _tableHeaderCell(isArabic ? 'الوصف' : 'Description', flex: 3),
            _tableHeaderCell(isArabic ? 'المرجع' : 'Réf.'),
          ].reversed.toList(),
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: index % 2 == 1 ? _tableRowAlternateBg : PdfColors.white),
            children: [
              if (showPrices) _tableCell(intl.NumberFormat('#,##0.00', 'en_US').format(item.total)),
              if (showPrices) _tableCell(intl.NumberFormat('#,##0.00', 'en_US').format(item.unitPrice)),
              _tableCell(item.unit),
              _tableCell(item.quantity.toString()),
              _tableCell(item.description.isNotEmpty ? item.description : (item.productName ?? ''), align: pw.Alignment.centerRight),
              _tableCell(item.productRef),
            ].reversed.toList(),
          );
        }),
      ],
    );
  }

  pw.Widget _tableHeaderCell(String text, {int flex = 1}) {
    return pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.center));
  }

  pw.Widget _tableCell(String text, {pw.Alignment align = pw.Alignment.center}) {
    return pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: pw.Text(text, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center));
  }

  pw.Widget _buildTotalsSection(AppDocument doc, List<DocumentItem> items, bool isArabic) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final discount = subtotal * (doc.discount / 100);
    final tva = (subtotal - discount) * (doc.tvaRate / 100);
    final total = (subtotal - discount) + tva + doc.deliveryFees;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 2, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('TVA non applicable selon l\'article 91 du CGI', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)), pw.SizedBox(height: 10), pw.Container(padding: const pw.EdgeInsets.all(8), decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6'), borderRadius: pw.BorderRadius.circular(4)), child: pw.Row(children: [pw.Text(isArabic ? 'المبلغ بالحروف: ' : 'Arrêté à la somme de: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)), pw.Expanded(child: pw.Text(AmountToWords.withCurrency(total), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryColor)))]))])),
        pw.SizedBox(width: 40),
        pw.Expanded(flex: 1, child: pw.Column(children: [_totalRow(isArabic ? 'المجموع الصافي' : 'Sous-total', intl.NumberFormat('#,##0.00', 'en_US').format(subtotal)), if (doc.discount > 0) _totalRow(isArabic ? 'الخصم (${doc.discount}%)' : 'Remise (${doc.discount}%)', '-${intl.NumberFormat('#,##0.00', 'en_US').format(discount)}'), _totalRow(isArabic ? 'الضريبة (${doc.tvaRate.toStringAsFixed(0)}%)' : 'TVA (${doc.tvaRate.toStringAsFixed(0)}%)', intl.NumberFormat('#,##0.00', 'en_US').format(tva)), if (doc.deliveryFees > 0) _totalRow(isArabic ? 'مصاريف التسليم' : 'Frais de livraison', intl.NumberFormat('#,##0.00', 'en_US').format(doc.deliveryFees)), pw.SizedBox(height: 5), pw.Container(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10), decoration: pw.BoxDecoration(color: _accentColor), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(isArabic ? 'المجموع' : 'TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)), pw.Text('${intl.NumberFormat('#,##0.00', 'en_US').format(total)} DH', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white))]))])),
      ],
    );
  }

  pw.Widget _totalRow(String label, String value) {
    return pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(label, style: const pw.TextStyle(fontSize: 10)), pw.Text('$value DH', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))]));
  }

  pw.Widget _buildDeliverySpecifics(AppDocument doc, bool isArabic) {
    return pw.Container(padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderColor), borderRadius: pw.BorderRadius.circular(4)), child: pw.Row(children: [pw.Text(isArabic ? 'مكان التسليم:' : 'Lieu de livraison:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)), pw.SizedBox(width: 5), pw.Text(doc.deliveryLocation ?? '---', style: const pw.TextStyle(fontSize: 10))]));
  }

  pw.Widget _buildSignatures(AppDocument doc, bool isArabic) {
    final isBDL = doc.type == 'BDL';
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(isArabic ? 'توقيع المورد' : 'Signature Expéditeur', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _primaryColor)), if (isBDL) ...[pw.SizedBox(height: 4), pw.Text(isArabic ? 'سلم في:' : 'Livré le:', style: const pw.TextStyle(fontSize: 9))], pw.SizedBox(height: 50), pw.Container(width: 120, height: 1, color: PdfColors.grey)]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text(isArabic ? 'توقيع الزبون' : 'Signature Client', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _primaryColor)), if (isBDL) ...[pw.SizedBox(height: 4), pw.Text(isArabic ? 'استلم في:' : 'Reçu le:', style: const pw.TextStyle(fontSize: 9))], pw.SizedBox(height: 50), pw.Container(width: 120, height: 1, color: PdfColors.grey)]),
      ],
    );
  }

  pw.Widget _buildFooter(Cooperative coop) {
    return pw.Container(alignment: pw.Alignment.center, margin: const pw.EdgeInsets.only(top: 20), child: pw.Column(children: [pw.Divider(color: _borderColor), pw.SizedBox(height: 5), pw.Text('${coop.name} | ${coop.phone ?? ""} | ${coop.email ?? ""}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))]));
  }

  Future<Uint8List?> fetchLogoAsBase64(String? logoUrl) async {
    if (logoUrl == null || logoUrl.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(logoUrl));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) { /* Error fetching logo */ }
    return null;
  }

  Future<Uint8List?> _fetchLogoBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) { /* Error fetching logo */ }
    return null;
  }

  static Future<String> getNextDocumentNumber(String type, String cooperativeId) async {
    final response = await Supabase.instance.client.from('documents').select('id').eq('type', type).eq('cooperative_id', cooperativeId);
    final count = (response as List).length + 1;
    String prefix = type == 'FAC' ? 'FAC' : (type == 'BDL' ? 'BDL' : (type == 'DEV' ? 'DEV' : 'DOC'));
    return '$prefix-${count.toString().padLeft(3, '0')}';
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
    await Share.shareXFiles([XFile(tempFile.path)], text: fileName);
  }

  Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
