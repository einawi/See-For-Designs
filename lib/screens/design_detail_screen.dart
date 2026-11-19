import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_for_designs/models/design_model.dart';
import 'package:see_for_designs/providers/design_provider.dart';
import 'package:see_for_designs/utils/pdf_generator.dart';
import 'dart:io';

class DesignDetailScreen extends StatelessWidget {
  final DesignModel design;
  const DesignDetailScreen({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(design.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: design.thumbnailPath != null && File(design.thumbnailPath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image.file(File(design.thumbnailPath!), fit: BoxFit.cover, width: double.infinity),
                      )
                    : const Center(child: Icon(Icons.image, size: 64.0, color: Color(0xFF38BDF8))),
              ),
            ),
            const SizedBox(height: 16.0),
            Text('Dimensions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DimensionColumn(label: 'Width', value: '${design.widthMm.toStringAsFixed(1)} mm'),
                _DimensionColumn(label: 'Height', value: '${design.heightMm.toStringAsFixed(1)} mm'),
                _DimensionColumn(label: 'Depth', value: '${design.depthMm.toStringAsFixed(1)} mm'),
              ],
            ),
            const SizedBox(height: 16.0),
            Text('Created: ${design.createdAt.toLocal().toString().split(' ').first}'),
            Text('File: ${design.fileName}'),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final provider = context.read<DesignProvider>();
                    await provider.moveToTrash(design.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Move to Trash'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final file = await PdfGenerator.generate(design);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('PDF saved to ${file.path}')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to generate PDF: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionColumn extends StatelessWidget {
  final String label;
  final String value;
  const _DimensionColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
