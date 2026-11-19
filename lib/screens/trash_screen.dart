import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_for_designs/models/design_model.dart';
import 'package:see_for_designs/providers/design_provider.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DesignProvider>();
    final trashed = provider.designs.where((d) => d.isTrashed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
      ),
      body: trashed.isEmpty
          ? const Center(child: Text('Trash is empty'))
          : ListView.builder(
              itemCount: trashed.length,
              itemBuilder: (context, index) {
                final design = trashed[index];
                return ListTile(
                  leading: Icon(Icons.image, color: const Color(0xFF38BDF8)),
                  title: Text(design.title),
                  subtitle: Text('${design.widthMm.toStringAsFixed(1)} x ${design.heightMm.toStringAsFixed(1)} x ${design.depthMm.toStringAsFixed(1)} mm'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore),
                        onPressed: () async {
                          await context.read<DesignProvider>().restoreDesign(design.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever),
                        onPressed: () async {
                          await context.read<DesignProvider>().deleteDesignPermanently(design.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
