import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:see_for_designs/models/design_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a single-page, printable A4 specification sheet as a PDF.
class PdfGenerator {
  static Future<File> generate(DesignModel design) async {
    final pdf = pw.Document();

    // Load thumbnail image if exists
    pw.MemoryImage? thumbnailImage;
    if (design.thumbnailPath != null) {
      final thumbFile = File(design.thumbnailPath!);
      if (await thumbFile.exists()) {
        final bytes = await thumbFile.readAsBytes();
        thumbnailImage = pw.MemoryImage(bytes);
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SEE FOR DESIGNS',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'SPECIFICATION SHEET',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 40,
                    height: 4,
                    color: PdfColor.fromInt(0xFF38BDF8),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Title
              pw.Text(
                design.title,
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                width: 120,
                height: 2,
                color: PdfColor.fromInt(0xFF38BDF8),
              ),
              pw.SizedBox(height: 24),

              // Preview
              pw.Container(
                width: double.infinity,
                height: 280,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: thumbnailImage != null
                    ? pw.Center(child: pw.Image(thumbnailImage, fit: pw.BoxFit.contain))
                    : pw.Center(
                        child: pw.Text(
                          'No preview available',
                          style: pw.TextStyle(color: PdfColors.grey500),
                        ),
                      ),
              ),
              pw.SizedBox(height: 24),

              // Dimensions
              pw.Text(
                'Dimensions (mm)',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildDimensionBox('Width', '${design.widthMm.toStringAsFixed(1)} mm'),
                  _buildDimensionBox('Height', '${design.heightMm.toStringAsFixed(1)} mm'),
                  _buildDimensionBox('Depth', '${design.depthMm.toStringAsFixed(1)} mm'),
                ],
              ),
              pw.SizedBox(height: 24),

              // Metadata
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Created: ${_formatDate(design.createdAt)}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text('File: ${design.fileName}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
              pw.SizedBox(height: 24),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Generated by See For Designs',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final Directory base = await getApplicationDocumentsDirectory();
    final Directory exportDir = Directory('${base.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final String safeName = _safeFileStem(design.title);
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final File file = File('${exportDir.path}/${safeName}_$stamp.pdf');

    final Uint8List bytes = await pdf.save();
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static pw.Widget _buildDimensionBox(String label, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
        ],
      ),
    );
  }

  static String _safeFileStem(String title) {
    final String cleaned = title
        .replaceAll(RegExp(r'[^A-Za-z0-9_\- ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'design' : cleaned;
  }

  static String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
