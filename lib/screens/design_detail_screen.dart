import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_for_designs/models/design_item.dart';
import 'package:see_for_designs/services/database_service.dart';
import 'package:see_for_designs/services/pdf_service.dart';
import 'package:intl/intl.dart';

class DesignDetailScreen extends StatelessWidget {
  const DesignDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final designId = ModalRoute.of(context)!.settings.arguments as String;
    final db = context.watch<DatabaseService>();

    return FutureBuilder<DesignItem?>(
      future: db.getDesignById(designId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final design = snapshot.data;
        if (design == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Design Not Found')),
            body: const Center(child: Text('Design not found')),
          );
        }
        return _DesignDetailView(design: design);
      },
    );
  }
}

class _DesignDetailView extends StatelessWidget {
  final DesignItem design;

  const _DesignDetailView({required this.design});

  Future<void> _moveToTrash(BuildContext context) async {
    final db = context.read<DatabaseService>();
    await db.updateDesign(design.copyWith(isTrashed: true));
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(design.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () => PdfService.generateAndShareSpecSheet(design),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: design.thumbnailPath.isNotEmpty
                  ? Image.file(
                      File(design.thumbnailPath),
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(theme, 300),
                    )
                  : _placeholder(theme, 300),
            ),
            const SizedBox(height: 24),

            // Dimensions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dimensions (mm)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _DimensionChip(
                          label: 'Width',
                          value: '${design.widthMm.toStringAsFixed(1)} mm',
                          theme: theme,
                        ),
                        const SizedBox(width: 12),
                        _DimensionChip(
                          label: 'Height',
                          value: '${design.heightMm.toStringAsFixed(1)} mm',
                          theme: theme,
                        ),
                        const SizedBox(width: 12),
                        _DimensionChip(
                          label: 'Depth',
                          value: '${design.depthMm.toStringAsFixed(1)} mm',
                          theme: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      design.dimensionsText,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'File',
                      value: design.filePath.split(Platform.pathSeparator).last,
                    ),
                    _DetailRow(
                      label: 'Created',
                      value: DateFormat.yMMMd().add_jm().format(design.createdAt),
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: design.isTrashed ? 'Trashed' : 'Active',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Move to Trash
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Move to Trash'),
                    onPressed: () => _moveToTrash(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme, double height) {
    return Container(
      height: height,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _DimensionChip extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DimensionChip({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
