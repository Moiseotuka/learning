import 'package:flutter/material.dart';

import '../models/analyse_models.dart';
import '../services/api_service.dart';
import 'syntheses_screen.dart';
import 'verbatims_screen.dart';
import 'rapport_screen.dart';

/// Ecran principal : tableau de bord de la consultation analysee.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AnalyseResult? _result;
  bool _loading = false;
  String? _error;
  bool _llmActive = true;

  @override
  void initState() {
    super.initState();
    _lancerAnalyse();
  }

  Future<void> _lancerAnalyse() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService(useLlm: _llmActive);
      final result = await api.analyserDemo();
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('CitizenSynth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _lancerAnalyse,
            tooltip: 'Relancer l\'analyse',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _result == null
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Tableau',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.insights),
                  label: 'Synthèses',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.format_quote),
                  label: 'Verbatims',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description),
                  label: 'Rapport',
                ),
              ],
              onTap: (index) {
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SynthesesScreen(result: _result!),
                    ),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerbatimsScreen(result: _result!),
                    ),
                  );
                } else if (index == 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RapportScreen(result: _result!),
                    ),
                  );
                }
              },
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyse du corpus en cours...'),
            SizedBox(height: 8),
            Text(
              'Prétraitement → LLM → Synthèses',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Impossible de joindre le serveur.\nVérifiez que le backend est lancé :\n\nuvicorn api_fastapi:app --port 8000',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _lancerAnalyse,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    final r = _result!;
    final majorPos = r.positionDistribution.entries.isNotEmpty
        ? (r.positionDistribution.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
        : null;

    return RefreshIndicator(
      onRefresh: _lancerAnalyse,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tete consultation
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget participatif — Commune X (Kinshasa)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${r.stats.exploitables} contributions analysées '
                    '| Modèle : ${_llmActive ? "LLM local" : "heuristique"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cartes statistiques
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                title: 'Contributions',
                value: '${r.stats.total}',
                color: Colors.blue,
                icon: Icons.people,
              ),
              _StatCard(
                title: 'Thèmes détectés',
                value: '${r.syntheses.length}',
                color: Colors.green,
                icon: Icons.category,
              ),
              _StatCard(
                title: 'Position majoritaire',
                value: majorPos != null
                    ? '${_positionLabel(majorPos.key)}\n${majorPos.value}'
                    : '—',
                color: _positionColor(majorPos?.key ?? ''),
                icon: Icons.trending_up,
              ),
              _StatCard(
                title: 'Taux d\'exploitation',
                value: '${r.stats.tauxExploitation} %',
                color: Colors.purple,
                icon: Icons.check_circle,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Distribution des themes
          Text(
            'Distribution des thèmes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...r.themeDistribution.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BarreTheme(libelle: e.key, valeur: e.value, max: r.stats.total),
            ),
          ),
          const SizedBox(height: 16),

          // Distribution des positions
          Text(
            'Distribution des positions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...r.positionDistribution.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _positionColor(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: Text(_positionLabel(e.key)),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: r.stats.total > 0 ? e.value / r.stats.total : 0,
                      color: _positionColor(e.key),
                      backgroundColor: Colors.grey.shade200,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.value}'),
                ],
              ),
            ),
          ),

          // Toggle LLM
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Utiliser le LLM (Ollama)'),
            subtitle: const Text(
              'Désactivé = classification heuristique plus rapide mais moins précise',
            ),
            value: _llmActive,
            onChanged: (v) {
              setState(() => _llmActive = v);
              _lancerAnalyse();
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarreTheme extends StatelessWidget {
  final String libelle;
  final int valeur;
  final int max;

  const _BarreTheme({
    required this.libelle,
    required this.valeur,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(libelle, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: max > 0 ? valeur / max : 0,
              minHeight: 14,
              backgroundColor: Colors.grey.shade200,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text('$valeur', textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
