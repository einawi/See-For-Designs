import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:see_for_designs/models/design_item.dart';
import 'package:see_for_designs/services/database_service.dart';
import 'package:see_for_designs/services/dwg_parser_service.dart';
import 'package:see_for_designs/widgets/duplicate_conflict_dialog.dart';
import 'package:see_for_designs/screens/design_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isImporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _importDwg() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dwg', 'DWG'],
      );
      if (result == null || result.files.single.path == null) return;

      final sourceFile = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final dwgDir = Directory('${appDir.path}/dwg_files');
      if (!await dwgDir.exists()) {
        await dwgDir.create(recursive: true);
      }
      final fileName = result.files.single.name;
      final destFile = File('${dwgDir.path}/$fileName');
      if (await destFile.exists()) {
        await destFile.delete();
      }
      await sourceFile.copy(destFile.path);

      final parsed = await DwgParserService.parseDwgFile(destFile);

      final existing = await _findDuplicate(parsed.title);
      if (existing != null && mounted) {
        final action = await showDialog<DuplicateAction>(
          context: context,
          builder: (context) => DuplicateConflictDialog(
            existing: existing,
            newTitle: parsed.title,
            newWidth: parsed.widthMm,
            newHeight: parsed.heightMm,
            newDepth: parsed.depthMm,
            newThumbnailPath: parsed.thumbnailPath,
            newFilePath: destFile.path,
          ),
        );
        if (action == DuplicateAction.keepExisting || action == null) {
          return;
        }
        if (action == DuplicateAction.replace) {
          final updated = existing.copyWith(
            title: parsed.title,
            widthMm: parsed.widthMm,
            heightMm: parsed.heightMm,
            depthMm: parsed.depthMm,
            filePath: destFile.path,
            thumbnailPath: parsed.thumbnailPath,
            isTrashed: false,
          );
          await context.read<DatabaseService>().updateDesign(updated);
          if (mounted) {
            Navigator.pushNamed(context, '/design', arguments: updated.id);
          }
          return;
        }
        // keepBoth
        final newItem = DesignItem(
          title: '${parsed.title} (Copy)',
          widthMm: parsed.widthMm,
          heightMm: parsed.heightMm,
          depthMm: parsed.depthMm,
          filePath: destFile.path,
          thumbnailPath: parsed.thumbnailPath,
        );
        await context.read<DatabaseService>().insertDesign(newItem);
        if (mounted) {
          Navigator.pushNamed(context, '/design', arguments: newItem.id);
        }
        return;
      }

      final newItem = DesignItem(
        title: parsed.title,
        widthMm: parsed.widthMm,
        heightMm: parsed.heightMm,
        depthMm: parsed.depthMm,
        filePath: destFile.path,
        thumbnailPath: parsed.thumbnailPath,
      );
      await context.read<DatabaseService>().insertDesign(newItem);
      if (mounted) {
        Navigator.pushNamed(context, '/design', arguments: newItem.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<DesignItem?> _findDuplicate(String title) async {
    final db = context.read<DatabaseService>();
    final designs = await db.getAllDesigns();
    try {
      return designs.firstWhere(
        (d) => !d.isTrashed && d.title.toLowerCase() == title.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('See For Designs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Trash',
            onPressed: () => Navigator.pushNamed(context, '/trash'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search designs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          // Catalog Grid
          Expanded(
            child: FutureBuilder<List<DesignItem>>(
              future: db.getAllDesigns(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final designs = snapshot.data ?? [];
                final filtered = designs.where((d) {
                  return d.title.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(theme);
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final design = filtered[index];
                    return _DesignCard(design: design);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isImporting ? null : _importDwg,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.design_services,
            size: 80,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No designs yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import a DWG file to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  final DesignItem design;

  const _DesignCard({required this.design});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, '/design', arguments: design.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: design.thumbnailPath.isNotEmpty
                    ? Image.file(
                        File(design.thumbnailPath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _placeholder(theme),
                      )
                    : _placeholder(theme),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    design.dimensionsText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
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
