import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:see_for_designs/models/design_item.dart';

class PdfService {
  static Future<void> generateAndShareSpecSheet(DesignItem design) async {
    final pdf = pw.Document();

    // Load thumbnail image
    final thumbnailFile = File(design.thumbnailPath);
    pw.MemoryImage? thumbnailImage;
    if (await thumbnailFile.exists()) {
      final bytes = await thumbnailFile.readAsBytes();
      thumbnailImage = pw.MemoryImage(bytes);
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
                        'See For Designs',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.Text(
                        'Woodworking Design Specification',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'SPEC SHEET',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 24),

              // Title
              pw.Text(
                design.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 16),

              // Preview and Dimensions side by side
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Preview
                  pw.Expanded(
                    flex: 2,
                    child: _buildPreview(thumbnailImage),
                  ),
                  pw.SizedBox(width: 24),
                  // Dimensions
                  pw.Expanded(
                    flex: 1,
                    child: _buildDimensions(design),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 16),
              pw.Text(
                'File: ${_fileName(design.filePath)}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                'Created: ${DateFormat.yMMMd().add_jm().format(design.createdAt)}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/spec_${design.id}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Design specification for ${design.title}',
    );
  }

  static pw.Widget _buildPreview(pw.MemoryImage? image) {
    if (image == null) {
      return pw.Container(
        height: 200,
        color: PdfColors.grey200,
        child: pw.Center(child: pw.Text('No Preview')),
      );
    }
    return pw.Container(
      height: 200,
      width: double.infinity,
      color: PdfColors.grey100,
      child: pw.Center(child: pw.Image(image)),
    );
  }

  static pw.Widget _buildDimensions(DesignItem design) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Dimensions (mm)',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Width: ${design.widthMm.toStringAsFixed(1)} mm'),
        pw.Text('Height: ${design.heightMm.toStringAsFixed(1)} mm'),
        pw.Text('Depth: ${design.depthMm.toStringAsFixed(1)} mm'),
      ],
    );
  }

  static String _fileName(String path) {
    final parts = path.split(Platform.pathSeparator);
    return parts.isNotEmpty ? parts.last : path;
  }
}
