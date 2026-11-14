import 'dart:io';
import 'package:flutter/material.dart';
import 'package:see_for_designs/models/design_item.dart';

enum DuplicateAction { keepExisting, replace, keepBoth }

class DuplicateConflictDialog extends StatelessWidget {
  final DesignItem existing;
  final String newTitle;
  final double newWidth;
  final double newHeight;
  final double newDepth;
  final String newThumbnailPath;
  final String newFilePath;

  const DuplicateConflictDialog({
    super.key,
    required this.existing,
    required this.newTitle,
    required this.newWidth,
    required this.newHeight,
    required this.newDepth,
    required this.newThumbnailPath,
    required this.newFilePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Duplicate Design Detected'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A design with nearly identical dimensions already exists in your catalog.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Existing Design', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _DesignPreview(
              title: existing.title,
              dimensions: existing.dimensionsText,
              thumbnailPath: existing.thumbnailPath,
            ),
            const SizedBox(height: 16),
            Text('New Import', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _DesignPreview(
              title: newTitle,
              dimensions: '${newWidth.toStringAsFixed(1)} × ${newHeight.toStringAsFixed(1)} × ${newDepth.toStringAsFixed(1)} mm',
              thumbnailPath: newThumbnailPath,
            ),
            const SizedBox(height: 16),
            Text('How would you like to proceed?', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, DuplicateAction.keepExisting),
          child: const Text('Keep Existing'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context, DuplicateAction.keepBoth),
          child: const Text('Keep Both'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, DuplicateAction.replace),
          child: const Text('Replace with New'),
        ),
      ],
    );
  }
}

class _DesignPreview extends StatelessWidget {
  final String title;
  final String dimensions;
  final String thumbnailPath;

  const _DesignPreview({
    required this.title,
    required this.dimensions,
    required this.thumbnailPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 140,
            width: double.infinity,
            child: thumbnailPath.isNotEmpty
                ? Image.file(
                    File(thumbnailPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _DesignPreviewPlaceholder(theme),
                  )
                : _DesignPreviewPlaceholder(theme),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          dimensions,
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

class _DesignPreviewPlaceholder extends StatelessWidget {
  final ThemeData theme;

  const _DesignPreviewPlaceholder(this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}
