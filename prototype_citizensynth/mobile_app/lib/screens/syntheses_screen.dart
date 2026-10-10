import 'package:flutter/material.dart';

import '../models/analyse_models.dart';

/// Ecran des fiches de synthese par theme.
class SynthesesScreen extends StatelessWidget {
  final AnalyseResult result;

  const SynthesesScreen({super.key, required this.result});

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

  @override
  Widget build(BuildContext context) {
    final syntheses = result.syntheses.values.toList()
      ..sort((a, b) => b.totalContributions.compareTo(a.totalContributions));

    return Scaffold(
      appBar: AppBar(title: const Text('Synthèses par thème')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: syntheses.length,
        itemBuilder: (context, index) {
          final s = syntheses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                s.libelle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${s.totalContributions} contributions '
                '| Confiance : ${s.confianceMoyenne.toStringAsFixed(2)}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distribution des positions
                      const Text(
                        'Positions',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...s.distributionPositions.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _positionColor(e.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  _positionLabel(e.key),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: e.value.part / 100,
                                  color: _positionColor(e.key),
                                  backgroundColor: Colors.grey.shade200,
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${e.value.part} %',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Points de blocage
                      if (s.pointsBlocage.isNotEmpty) ...[
                        const Text(
                          'Points de blocage',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...s.pointsBlocage.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber,
                                    size: 16, color: Colors.red),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(b,
                                      style: const TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Propositions
                      if (s.propositions.isNotEmpty) ...[
                        const Text(
                          'Propositions constructives',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...s.propositions.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb_outline,
                                    size: 16, color: Colors.green),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(p,
                                      style: const TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Verbatims
                      const Text(
                        'Verbatims d\'appui (traçabilité)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ...s.verbatims.entries.expand((entry) {
                        return entry.value.map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: _positionColor(entry.key),
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                '[${_positionLabel(entry.key)} | id=${v.id}] ${v.texte}',
                                style: const TextStyle(
                                    fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
