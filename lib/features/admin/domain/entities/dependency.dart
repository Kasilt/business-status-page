/// Représente une dépendance entre deux CIs.
/// Analogie AS/400 : Fichier de liens (Logical File ou Cross-Reference File)
/// Ex: CI "Prise de commande" (Business) dépend de CI "Base de données" (Technique)
class Dependency {
  final String id;
  final String sourceCiId; // Le CI qui dépend de l'autre (ex: Business)
  final String targetCiId; // Le CI dont on dépend (ex: Database)
  
  /// Poids de l'impact (0.0 à 1.0 ou entier)
  /// Si le target tombe, à quel point le parent est touché ?
  final int impactWeight; 

  /// (Optionnel) Si la relation n'est vraie que pour certaines BUs
  /// Analogie: Enregistrement d'exception
  final List<String>? buFilter;

  Dependency({
    required this.id,
    required this.sourceCiId,
    required this.targetCiId,
    this.impactWeight = 100, // 100% d'impact par défaut
    this.buFilter,
  });
}
