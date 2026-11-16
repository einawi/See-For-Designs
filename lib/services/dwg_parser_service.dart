import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ParsedDwgResult {
  final String title;
  final double widthMm;
  final double heightMm;
  final double depthMm;
  final String thumbnailPath;

  ParsedDwgResult({
    required this.title,
    required this.widthMm,
    required this.heightMm,
    required this.depthMm,
    required this.thumbnailPath,
  });
}

class DwgParserService {
  static const double _thumbnailSize = 300;

  /// Simulates parsing a DWG file by generating a thumbnail and random dimensions.
  /// In a real app, this would use a native DWG parser (e.g., via FFI or platform channel).
  static Future<ParsedDwgResult> parseDwgFile(File dwgFile) async {
    // Simulate parsing delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate a deterministic but unique thumbnail based on file path hash
    final hash = dwgFile.path.hashCode;
    final random = Random(hash);

    // Generate dimensions in mm (typical woodworking sizes)
    final width = 100 + random.nextDouble() * 2000; // 100mm - 2100mm
    final height = 50 + random.nextDouble() * 1500; // 50mm - 1550mm
    final depth = 10 + random.nextDouble() * 100; // 10mm - 110mm

    // Create a thumbnail image programmatically
    final thumbnailPath = await _generateThumbnail(dwgFile.path, random);

    // Extract a title from the file name
    final fileName = dwgFile.path.split(Platform.pathSeparator).last;
    final title = fileName.replaceAll('.dwg', '').replaceAll('.DWG', '');

    return ParsedDwgResult(
      title: title,
      widthMm: width,
      heightMm: height,
      depthMm: depth,
      thumbnailPath: thumbnailPath,
    );
  }

  static Future<String> _generateThumbnail(String sourcePath, Random random) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(_thumbnailSize, _thumbnailSize);

    // Background
    final bgPaint = Paint()..color = const Color(0xFF0B0F19);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw a simple geometric representation (simulated CAD preview)
    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw a few random rectangles and lines to simulate a CAD drawing
    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width * 0.8 + size.width * 0.1;
      final y = random.nextDouble() * size.height * 0.8 + size.height * 0.1;
      final w = random.nextDouble() * 60 + 20;
      final h = random.nextDouble() * 60 + 20;
      final rect = Rect.fromLTWH(x, y, w, h);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, linePaint);
    }

    // Add some dimension lines
    final dimPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.7)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final x1 = random.nextDouble() * size.width;
      final y1 = random.nextDouble() * size.height;
      final x2 = random.nextDouble() * size.width;
      final y2 = random.nextDouble() * size.height;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dimPaint);
    }

    // Add a border
    final borderPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(_thumbnailSize.toInt(), _thumbnailSize.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    final dir = await getApplicationDocumentsDirectory();
    final thumbDir = Directory('${dir.path}/thumbnails');
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    final thumbFile = File('${thumbDir.path}/${const Uuid().v4()}.png');
    await thumbFile.writeAsBytes(bytes!.buffer.asUint8List());
    return thumbFile.path;
  }
}
