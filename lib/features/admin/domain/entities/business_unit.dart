/// Représente une Business Unit (Entité Métier / Localisation)
/// Analogie AS/400 : Code Société (SOC) ou Code Dépôt.
class BusinessUnit {
  final String id;
  final String name;
  final String code; // Ex: "PAR" pour Paris

  BusinessUnit({
    required this.id,
    required this.name,
    required this.code,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessUnit &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
