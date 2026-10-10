import 'package:flutter/material.dart';

import '../models/analyse_models.dart';

/// Ecran de consultation des verbatims analyses (avec filtres).
class VerbatimsScreen extends StatefulWidget {
  final AnalyseResult result;

  const VerbatimsScreen({super.key, required this.result});

  @override
  State<VerbatimsScreen> createState() => _VerbatimsScreenState();
}

class _VerbatimsScreenState extends State<VerbatimsScreen> {
  String _filtreTheme = 'Tous';
  String _filtrePosition = 'Toutes';

  Color _positionColor(String pos) {
    switch (pos) {
      case 'favorable':
        return Colors.green;
      case 'defavorable':
        return Colors.red;
      case 'nuancee':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _positionLabel(String pos) {
    switch (pos) {
      case 'favorable':
        return 'Favorable';
      case 'defavorable':
        return 'Défavorable';
      case 'nuancee':
        return 'Nuancée';
      default:
        return 'Indéterminée';
    }
  }

  List<Contribution> get _filtrees {
    return widget.result.contributions.where((c) {
      if (_filtreTheme != 'Tous' && !c.themes.contains(_filtreTheme)) {
        return false;
      }
      if (_filtrePosition != 'Toutes' && c.position != _filtrePosition) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themesDispo = widget.result.syntheses.keys.toList();
    final liste = _filtrees;

    return Scaffold(
      appBar: AppBar(title: const Text('Verbatims analysés')),
      body: Column(
        children: [
          // Filtres
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filtreTheme,
                    decoration: const InputDecoration(
                      labelText: 'Thème',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                      ...themesDispo.map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.replaceAll('_', ' ')),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _filtreTheme = v ?? 'Tous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filtrePosition,
                    decoration: const InputDecoration(
                      labelText: 'Position',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Toutes', child: Text('Toutes')),
                      DropdownMenuItem(
                          value: 'favorable', child: Text('Favorable')),
                      DropdownMenuItem(
                          value: 'defavorable', child: Text('Défavorable')),
                      DropdownMenuItem(
                          value: 'nuancee', child: Text('Nuancée')),
                      DropdownMenuItem(
                          value: 'indeterminee', child: Text('Indéterminée')),
                    ],
                    onChanged: (v) =>
                        setState(() => _filtrePosition = v ?? 'Toutes'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${liste.length} contribution(s)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          // Liste
          Expanded(
            child: liste.isEmpty
                ? const Center(child: Text('Aucune contribution pour ce filtre.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: liste.length,
                    itemBuilder: (context, index) {
                      final c = liste[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'ID ${c.id ?? "-"}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          _positionColor(c.position).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _positionColor(c.position),
                                      ),
                                    ),
                                    child: Text(
                                      _positionLabel(c.position),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _positionColor(c.position),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Themes
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: c.themes
                                    .map(
                                      (t) => Chip(
                                        label: Text(
                                          t.replaceAll('_', ' '),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 8),
                              Text(c.texte),
                              if (c.proposition != null &&
                                  c.proposition!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Proposition : ${c.proposition}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                'Confiance : ${c.confiance.toStringAsFixed(2)}'
                                ' | Méthode : ${c.methode}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
