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
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/document.dart';
import '../../shared/models/cooperative.dart';
import '../../core/utils/amount_to_words.dart';

class PdfService {
  // Brand Colors
  static final _primaryColor = PdfColor.fromHex('1A2A4A'); // Dark Navy
  static final _accentColor  = PdfColor.fromHex('FF8C00'); // Orange
  static final _tableHeaderBg = _primaryColor;
  static final _tableRowAlternateBg = PdfColor.fromHex('F9FAFB');
  static final _borderColor = PdfColor.fromHex('E5E7EB');

  /// Main entry point to generate PDF
  Future<pw.Document> generateDocumentPdf({
    required AppDocument document,
    required Cooperative cooperative,
    required List<DocumentItem> items,
    bool isArabic = true,
  }) async {
    final pdf = pw.Document();

    // Load Fonts for Bilingual support
    final font = await PdfGoogleFonts.amiriRegular();
    final fontBold = await PdfGoogleFonts.amiriBold();

    // Fetch Logo
    pw.MemoryImage? logoImage;
    if (cooperative.logoUrl != null && cooperative.logoUrl!.isNotEmpty) {
      final logoBytes = await _fetchLogoBytes(cooperative.logoUrl!);
      if (logoBytes != null) {
        logoImage = pw.MemoryImage(logoBytes);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        textDirection: pw.TextDirection.rtl, // RTL as base for Arabic
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        header: (context) => _buildHeader(cooperative, document, isArabic, logoImage),
        footer: (context) => _buildFooter(cooperative),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildInfoSection(document, isArabic),
          pw.SizedBox(height: 25),
          _buildItemsTable(items, document.type, isArabic),
          pw.SizedBox(height: 20),
          
          // Document Specific Bottom Sections
          if (document.type == 'FAC') ...[
            _buildTotalsSection(document, items, isArabic),
          ] else if (document.type == 'BDL') ...[
            _buildDeliverySpecifics(document, isArabic),
          ] else if (document.type == 'BDC') ...[
            _buildOrderSpecifics(document, isArabic),
            pw.SizedBox(height: 15),
            _buildTotalsSection(document, items, isArabic),
          ],
          
          pw.SizedBox(height: 30),
          _buildSignatures(document, isArabic),
        ],
      ),
    );

    return pdf;
  }

  // --- HEADER SECTION ---
  pw.Widget _buildHeader(Cooperative coop, AppDocument doc, bool isArabic, pw.MemoryImage? logoImage) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Cooperative Details (Left)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  coop.name,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                ),
                pw.SizedBox(height: 4),
                _headerInfoText(coop.address ?? ''),
                _headerInfoText(coop.phone ?? ''),
                _headerInfoText(coop.email ?? ''),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    if (coop.rc != null) _headerInfoText('RC: ${coop.rc}  '),
                    if (coop.ice != null) _headerInfoText('ICE: ${coop.ice}'),
                  ],
                ),
              ],
            ),

            // Logo (Right)
            if (logoImage != null)
              pw.Container(
                width: 70,
                height: 70,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              )
            else
              pw.Container(
                width: 70,
                height: 70,
                decoration: pw.BoxDecoration(
                  color: _primaryColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  coop.name.isNotEmpty ? coop.name.substring(0, 1).toUpperCase() : 'C',
                  style: pw.TextStyle(fontSize: 30, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Divider(color: _borderColor, thickness: 1),
        pw.SizedBox(height: 10),
        
        // Document Type and Number
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  doc.typeLabel,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                ),
                pw.Text(
                  doc.number,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _accentColor),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  isArabic ? 'التاريخ:' : 'Date:',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  intl.DateFormat('dd/MM/yyyy').format(doc.date),
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _headerInfoText(String text) {
    return pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700));
  }

  // --- INFO SECTION (Client/Supplier) ---
  pw.Widget _buildInfoSection(AppDocument doc, bool isArabic) {
    final isSupplier = doc.type == 'BDC';
    final name = isSupplier ? (doc.supplierName ?? '') : (doc.clientName ?? '');
    final phone = doc.clientPhone ?? '';
    final address = doc.clientAddress ?? '';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isSupplier 
                ? (isArabic ? 'المورد:' : 'FOURNISSEUR:') 
                : (isArabic ? 'الزبون:' : 'CLIENT:'),
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _primaryColor),
          ),
          pw.SizedBox(height: 5),
          pw.Text(name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (phone.isNotEmpty) _headerInfoText(phone),
          if (address.isNotEmpty) _headerInfoText(address),
        ],
      ),
    );
  }

  // --- ITEMS TABLE ---
  pw.Widget _buildItemsTable(List<DocumentItem> items, String docType, bool isArabic) {
    final showPrices = docType != 'BDL';

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _borderColor, width: 0.5),
        bottom: pw.BorderSide(color: _primaryColor, width: 1),
      ),
      children: [
        // Table Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _tableHeaderBg),
          children: [
            if (showPrices) _tableHeaderCell(isArabic ? 'المجموع' : 'Total'),
            if (showPrices) _tableHeaderCell(isArabic ? 'الثمن الوحدوي' : 'P.U'),
            _tableHeaderCell(isArabic ? 'الوحدة' : 'Unité'),
            _tableHeaderCell(isArabic ? 'الكمية' : 'Qté'),
            _tableHeaderCell(isArabic ? 'الوصف' : 'Description', flex: 3),
            _tableHeaderCell(isArabic ? 'المرجع' : 'Réf.'),
          ].reversed.toList(), // Reverse for RTL if needed, but Table handles it with textDirection
        ),
        // Table Body
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index % 2 == 1 ? _tableRowAlternateBg : PdfColors.white,
            ),
            children: [
              if (showPrices) _tableCell(item.total.toStringAsFixed(2)),
              if (showPrices) _tableCell(item.unitPrice.toStringAsFixed(2)),
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
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _tableCell(String text, {pw.Alignment align = pw.Alignment.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // --- TOTALS SECTION ---
  pw.Widget _buildTotalsSection(AppDocument doc, List<DocumentItem> items, bool isArabic) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final total = subtotal; // Assuming no VAT for now as per instructions

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left Side: Legal mention and Amount in words
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TVA non applicable selon l\'article 91 du CGI',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('F3F4F6'),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      isArabic ? 'المبلغ بالحروف: ' : 'Arrêté à la somme de: ',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        AmountToWords.withCurrency(total), // French words as per existing util
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        // Right Side: Totals
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            children: [
              _totalRow(isArabic ? 'المجموع الصافي' : 'Sous-total', subtotal.toStringAsFixed(2)),
              _totalRow(isArabic ? 'الضريبة (0%)' : 'TVA (0%)', '0.00'),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: pw.BoxDecoration(color: _accentColor),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      isArabic ? 'المجموع' : 'TOTAL',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                    pw.Text(
                      '${total.toStringAsFixed(2)} DH',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _totalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text('$value DH', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // --- BDL SPECIFICS ---
  pw.Widget _buildDeliverySpecifics(AppDocument doc, bool isArabic) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                isArabic ? 'مكان التسليم:' : 'Lieu de livraison:',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(width: 5),
              pw.Text(doc.deliveryLocation ?? '---', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // --- BDC SPECIFICS ---
  pw.Widget _buildOrderSpecifics(AppDocument doc, bool isArabic) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                isArabic ? 'تاريخ التسليم المتوقع:' : 'Date de livraison prévue:',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(width: 5),
              pw.Text(doc.deliveryDelay ?? '---', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Text(
                isArabic ? 'شروط الأداء:' : 'Modalité de paiement:',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(width: 5),
              pw.Text(doc.paymentMethod ?? '---', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // --- SIGNATURES ---
  pw.Widget _buildSignatures(AppDocument doc, bool isArabic) {
    final isBDL = doc.type == 'BDL';
    
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Left: Expéditeur
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              isArabic ? 'توقيع المورد' : 'Signature Expéditeur',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _primaryColor),
            ),
            if (isBDL) ...[
              pw.SizedBox(height: 4),
              pw.Text(isArabic ? 'سلم في:' : 'Livré le:', style: const pw.TextStyle(fontSize: 9)),
            ],
            pw.SizedBox(height: 50),
            pw.Container(width: 120, height: 1, color: PdfColors.grey),
          ],
        ),
        // Right: Client
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              isArabic ? 'توقيع الزبون' : 'Signature Client',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _primaryColor),
            ),
            if (isBDL) ...[
              pw.SizedBox(height: 4),
              pw.Text(isArabic ? 'استلم في:' : 'Reçu le:', style: const pw.TextStyle(fontSize: 9)),
            ],
            pw.SizedBox(height: 50),
            pw.Container(width: 120, height: 1, color: PdfColors.grey),
          ],
        ),
      ],
    );
  }

  // --- FOOTER ---
  pw.Widget _buildFooter(Cooperative coop) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          pw.Divider(color: _borderColor),
          pw.SizedBox(height: 5),
          pw.Text(
            '${coop.name} | ${coop.phone ?? ""} | ${coop.email ?? ""}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // --- UTILS ---

  Future<Uint8List?> fetchLogoAsBase64(String? logoUrl) async {
    if (logoUrl == null || logoUrl.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(logoUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error fetching logo: $e');
    }
    return null;
  }

  Future<Uint8List?> _fetchLogoBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error fetching logo: $e');
    }
    return null;
  }

  static Future<String> getNextDocumentNumber(String type, String cooperativeId) async {
    final response = await Supabase.instance.client
        .from('documents')
        .select('id')
        .eq('type', type)
        .eq('cooperative_id', cooperativeId);
    
    final count = (response as List).length + 1;
    String prefix = '';
    switch (type) {
      case 'FAC': prefix = 'FAC'; break;
      case 'BDL': prefix = 'BDL'; break;
      case 'BDC': prefix = 'BC'; break;
      default: prefix = 'DOC';
    }
    
    return '$prefix-${count.toString().padLeft(3, '0')}';
  }

  // --- EXISTING METHODS RE-IMPLEMENTED FOR COMPATIBILITY ---

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

