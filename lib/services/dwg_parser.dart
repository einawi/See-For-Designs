import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:see_for_designs/models/design_model.dart';
import 'package:uuid/uuid.dart';

class DwgParser {
  static final Uuid _uuid = Uuid();
  static final Random _random = Random();

  static Future<DesignModel> parseDwgFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('DWG file not found: $filePath');
    }
    final fileName = file.uri.pathSegments.last;
    final title = fileName.split('.').first.replaceAll('_', ' ');

    // Simulate parsing: generate random dimensions between 100 and 2000 mm
    final width = 100.0 + _random.nextDouble() * 1900.0;
    final height = 100.0 + _random.nextDouble() * 1900.0;
    final depth = 10.0 + _random.nextDouble() * 100.0;

    final design = DesignModel(
      id: _uuid.v4(),
      title: title,
      widthMm: width,
      heightMm: height,
      depthMm: depth,
      fileName: fileName,
      createdAt: DateTime.now(),
      isTrashed: false,
    );

    // Generate thumbnail
    await generateThumbnail(filePath, design.id);
    return design;
  }

  static Future<void> generateThumbnail(String filePath, String designId) async {
    // Create a simple placeholder image (colored rectangle) and save to app directory
    final directory = await getApplicationDocumentsDirectory();
    final thumbDir = Directory('${directory.path}/thumbnails');
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    final thumbFile = File('${thumbDir.path}/$designId.png');

    // Use a simple picture recorder to draw a placeholder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(200, 200);
    final paint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    // Draw a border
    final borderPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
    // Draw text "DWG"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'DWG',
        style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      await thumbFile.writeAsBytes(byteData.buffer.asUint8List());
    }
  }

  static DesignModel calculateDimensions(DesignModel design) {
    // In a real implementation, this would compute dimensions from DWG geometry.
    // For now, we return the design as is.
    return design;
  }
}
