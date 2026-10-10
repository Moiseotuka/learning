/// Modeles de donnees pour l'API CitizenSynth.
library;

class Contribution {
  final int? id;
  final String texte;
  final List<String> themes;
  final String? themePrincipal;
  final String position;
  final List<String> arguments;
  final String? proposition;
  final double confiance;
  final String methode;

  Contribution({
    this.id,
    required this.texte,
    required this.themes,
    this.themePrincipal,
    required this.position,
    required this.arguments,
    this.proposition,
    required this.confiance,
    required this.methode,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'],
      texte: json['texte'] ?? '',
      themes: List<String>.from(json['themes'] ?? []),
      themePrincipal: json['themePrincipal'],
      position: json['position'] ?? 'indeterminee',
      arguments: List<String>.from(json['arguments'] ?? []),
      proposition: json['proposition'],
      confiance: (json['confiance'] ?? 0).toDouble(),
      methode: json['methode'] ?? '',
    );
  }
}

class PositionInfo {
  final double part;
  final int nb;

  PositionInfo({required this.part, required this.nb});

  factory PositionInfo.fromJson(Map<String, dynamic> json) {
    return PositionInfo(
      part: (json['part'] ?? 0).toDouble(),
      nb: json['nb'] ?? 0,
    );
  }
}

class Verbatim {
  final int? id;
  final String texte;

  Verbatim({this.id, required this.texte});

  factory Verbatim.fromJson(Map<String, dynamic> json) {
    return Verbatim(id: json['id'], texte: json['texte'] ?? '');
  }
}

class Synthese {
  final String theme;
  final String libelle;
  final int totalContributions;
  final Map<String, PositionInfo> distributionPositions;
  final List<String> pointsBlocage;
  final List<String> propositions;
  final Map<String, List<Verbatim>> verbatims;
  final double confianceMoyenne;

  Synthese({
    required this.theme,
    required this.libelle,
    required this.totalContributions,
    required this.distributionPositions,
    required this.pointsBlocage,
    required this.propositions,
    required this.verbatims,
    required this.confianceMoyenne,
  });

  factory Synthese.fromJson(Map<String, dynamic> json) {
    final dist = <String, PositionInfo>{};
    final distJson = json['distributionPositions'] as Map<String, dynamic>? ?? {};
    distJson.forEach((key, value) {
      dist[key] = PositionInfo.fromJson(value);
    });

    final verbs = <String, List<Verbatim>>{};
    final verbsJson = json['verbatims'] as Map<String, dynamic>? ?? {};
    verbsJson.forEach((key, value) {
      verbs[key] = (value as List)
          .map((v) => Verbatim.fromJson(v as Map<String, dynamic>))
          .toList();
    });

    return Synthese(
      theme: json['theme'] ?? '',
      libelle: json['libelle'] ?? '',
      totalContributions: json['totalContributions'] ?? 0,
      distributionPositions: dist,
      pointsBlocage: List<String>.from(json['pointsBlocage'] ?? []),
      propositions: List<String>.from(json['propositions'] ?? []),
      verbatims: verbs,
      confianceMoyenne: (json['confianceMoyenne'] ?? 0).toDouble(),
    );
  }
}

class Stats {
  final int total;
  final int exploitables;
  final int tropCourts;
  final int doublons;
  final int ecartes;
  final double tauxExploitation;

  Stats({
    required this.total,
    required this.exploitables,
    required this.tropCourts,
    required this.doublons,
    required this.ecartes,
    required this.tauxExploitation,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      total: json['total'] ?? 0,
      exploitables: json['exploitables'] ?? 0,
      tropCourts: json['trop_courts'] ?? 0,
      doublons: json['doublons'] ?? 0,
      ecartes: json['ecartes'] ?? 0,
      tauxExploitation: (json['taux_exploitation'] ?? 0).toDouble(),
    );
  }
}

class AnalyseResult {
  final Stats stats;
  final Map<String, int> themeDistribution;
  final Map<String, int> positionDistribution;
  final Map<String, Synthese> syntheses;
  final List<Contribution> contributions;
  final String rapport;

  AnalyseResult({
    required this.stats,
    required this.themeDistribution,
    required this.positionDistribution,
    required this.syntheses,
    required this.contributions,
    required this.rapport,
  });

  factory AnalyseResult.fromJson(Map<String, dynamic> json) {
    return AnalyseResult(
      stats: Stats.fromJson(json['stats'] ?? {}),
      themeDistribution: Map<String, int>.from(json['themeDistribution'] ?? {}),
      positionDistribution:
          Map<String, int>.from(json['positionDistribution'] ?? {}),
      syntheses: (json['syntheses'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, Synthese.fromJson(v))),
      contributions: (json['contributions'] as List? ?? [])
          .map((c) => Contribution.fromJson(c))
          .toList(),
      rapport: json['rapport'] ?? '',
    );
  }
}
