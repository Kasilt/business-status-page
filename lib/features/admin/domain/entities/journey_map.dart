class JourneyMap {
  final String id;
  final String name;
  final String? description;
  final List<JourneyMapCI> cis;
  final List<String> tags;

  JourneyMap({
    required this.id,
    required this.name,
    this.description,
    this.cis = const [],
    this.tags = const [],
  });

  factory JourneyMap.fromJson(Map<String, dynamic> json) {
    return JourneyMap(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      cis: (json['journey_map_cis'] as List<dynamic>?)
              ?.map((ci) => JourneyMapCI.fromJson(ci))
              .toList() ??
          [],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'tags': tags,
    };
  }
}

class JourneyMapCI {
  final String journeyMapId;
  final String ciId;
  final int position;

  JourneyMapCI({
    required this.journeyMapId,
    required this.ciId,
    this.position = 0,
  });

  factory JourneyMapCI.fromJson(Map<String, dynamic> json) {
    return JourneyMapCI(
      journeyMapId: json['journey_map_id'],
      ciId: json['ci_id'],
      position: json['position'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journey_map_id': journeyMapId,
      'ci_id': ciId,
      'position': position,
    };
  }
}
