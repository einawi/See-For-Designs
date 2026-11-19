import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:see_for_designs/models/design_model.dart';
import 'package:see_for_designs/providers/design_provider.dart';
import 'package:see_for_designs/screens/design_detail_screen.dart';
import 'package:see_for_designs/screens/trash_screen.dart';
import 'package:see_for_designs/services/dwg_parser.dart';
import 'package:see_for_designs/widgets/duplicate_dialog.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDwg() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dwg'],
    );
    if (result == null) return;
    final file = result.files.first;
    final path = file.path;
    if (path == null) return;
    try {
      final design = await DwgParser.parseDwgFile(path);
      if (mounted) {
        await context.read<DesignProvider>().addDesign(design);
      }
    } on DuplicateDesignException catch (e) {
      if (mounted) {
        final resolution = await DuplicateDialog.show(
          context,
          existing: e.existing,
          incoming: e.incoming,
        );
        if (resolution == null) return;
        final provider = context.read<DesignProvider>();
        switch (resolution) {
          case DuplicateResolution.keepExisting:
            // Do nothing, keep existing
            break;
          case DuplicateResolution.replaceWithNew:
            await provider.replaceDesign(e.existing, e.incoming);
            break;
          case DuplicateResolution.keepBoth:
            await provider.keepBoth(e.existing, e.incoming);
            break;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DesignProvider>();
    final designs = provider.designs.where((d) => !d.isTrashed).toList();
    designs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    final filtered = designs.where((d) => d.title.toLowerCase().contains(_query.toLowerCase())).toList();

    // Group by first letter
    final Map<String, List<DesignModel>> grouped = {};
    for (final design in filtered) {
      final firstLetter = design.title.isNotEmpty ? design.title[0].toUpperCase() : '#';
      grouped.putIfAbsent(firstLetter, () => []).add(design);
    }
    final sortedLetters = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('See For Designs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search designs...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No designs found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: sortedLetters.length,
                    itemBuilder: (context, index) {
                      final letter = sortedLetters[index];
                      final letterDesigns = grouped[letter]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              letter,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF38BDF8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: letterDesigns.length,
                            itemBuilder: (context, i) {
                              final design = letterDesigns[i];
                              return _DesignCard(design: design);
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickDwg,
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: const Color(0xFF0B0F19),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  final DesignModel design;
  const _DesignCard({required this.design});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/design', arguments: design);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: design.thumbnailPath != null && File(design.thumbnailPath!).existsSync()
                  ? Image.file(File(design.thumbnailPath!), fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(Icons.image, size: 48, color: Color(0xFF38BDF8)),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${design.widthMm.toStringAsFixed(1)} × ${design.heightMm.toStringAsFixed(1)} × ${design.depthMm.toStringAsFixed(1)} mm',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
