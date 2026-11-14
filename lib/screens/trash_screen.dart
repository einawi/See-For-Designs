import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_for_designs/models/design_item.dart';
import 'package:see_for_designs/services/database_service.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<DesignItem>>(
        future: db.getAllDesigns(trashedOnly: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final designs = snapshot.data ?? [];
          if (designs.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: designs.length,
            itemBuilder: (context, index) {
              final design = designs[index];
              return _TrashItem(design: design);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep, size: 80, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Trash is empty',
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              'Deleted designs will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrashItem extends StatelessWidget {
  final DesignItem design;

  const _TrashItem({required this.design});

  Future<void> _restore(BuildContext context) async {
    final db = context.read<DatabaseService>();
    await db.updateDesign(design.copyWith(isTrashed: false));
  }

  Future<void> _deletePermanently(BuildContext context) async {
    final db = context.read<DatabaseService>();
    await db.deleteDesignPermanently(design.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: design.thumbnailPath.isNotEmpty
              ? Image.file(
                  File(design.thumbnailPath),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                )
              : Icon(Icons.image_not_supported, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        ),
        title: Text(
          design.title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          design.dimensionsText,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Restore',
              onPressed: () {
                _restore(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete Permanently',
              onPressed: () {
                _deletePermanently(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
