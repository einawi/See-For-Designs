import 'package:flutter/material.dart';
import 'package:see_for_designs/models/design_model.dart';

enum DuplicateResolution { keepExisting, replaceWithNew, keepBoth }

class DuplicateDialog extends StatelessWidget {
  final DesignModel existing;
  final DesignModel incoming;

  const DuplicateDialog({
    super.key,
    required this.existing,
    required this.incoming,
  });

  static Future<DuplicateResolution?> show(
    BuildContext context, {
    required DesignModel existing,
    required DesignModel incoming,
  }) {
    return showDialog<DuplicateResolution>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DuplicateDialog(existing: existing, incoming: incoming),
    );
  }

  static String _formatDimensions(DesignModel design) {
    return '${design.widthMm.toStringAsFixed(1)} x '
        '${design.heightMm.toStringAsFixed(1)} x '
        '${design.depthMm.toStringAsFixed(1)} mm';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: const Text('Duplicate design'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A design named "${existing.title}" already exists. '
              'Choose how to handle the imported file.',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PreviewCard(
                    label: 'Existing',
                    design: existing,
                    accent: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: _PreviewCard(
                    label: 'New',
                    design: incoming,
                    accent: const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowButtonSpacing: 8.0,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(DuplicateResolution.keepExisting),
          child: const Text('Keep Existing'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(DuplicateResolution.keepBoth),
          child: const Text('Keep Both'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(DuplicateResolution.replaceWithNew),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF38BDF8),
            foregroundColor: const Color(0xFF0B0F19),
          ),
          child: const Text('Replace with New'),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String label;
  final DesignModel design;
  final Color accent;

  const _PreviewCard({
    required this.label,
    required this.design,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0F19),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: const Center(
            child: Icon(Icons.image, size: 40, color: Color(0xFF38BDF8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(design.title, style: Theme.of(context).textTheme.bodyMedium),
        Text(DuplicateDialog._formatDimensions(design), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF94A3B8))),
      ],
    );
  }
}
