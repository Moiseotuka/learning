import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/analyse_models.dart';

/// Ecran du rapport global exportable (copie dans le presse-papier).
class RapportScreen extends StatelessWidget {
  final AnalyseResult result;

  const RapportScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport global'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copier le rapport',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: result.rapport));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rapport copié.')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            result.rapport,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: result.rapport));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rapport copié dans le presse-papier.')),
                );
              }
            },
            icon: const Icon(Icons.copy_all),
            label: const Text('Copier pour partage'),
          ),
        ),
      ),
    );
  }
}
