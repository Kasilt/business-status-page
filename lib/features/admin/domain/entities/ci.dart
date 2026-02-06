import 'daily_status.dart';

enum CIType {
  technical, // Serveur, Base de données...
  application, // App JDR, App Compta...
  businessService, // Prise de commande, Encaissement...
}

enum CIStatus {
  operational, // Opérationnel (Operational) - Vert
  degraded, // Dégradé (Degraded) - Orange
  down, // Panne (Outage) - Rouge
  maintenance, // Maintenance (Maintenance) - Gris/Bleu
}

enum CIScope {
  global, // Instance unique pour tout le monde (Ex: Siège)
  local, // Instance spécifique par BU (Ex: Magasin)
}

/// Configuration Item (CI)
/// Analogie AS/400 : Enregistrement du fichier "CONFIG"
class CI {
  final String id;
  final String name;
  final String description;
  final CIType type;
  
  // Analogie : Champ "STATUT" dans l'enregistrement
  final CIStatus status; // Statut manuel ou brut (avant calcul)

  // Nouveaux champs pour la gestion "Poupées Russes"
  final CIScope scope;
  final String? owner; // Responsable
  final Map<String, dynamic> attributes; // Champs libres (Extended attrs)

  // Historique (Barre de vie) - Analogie: Sous-fichier d'historique
  final int historyRetentionDays; 
  // Ce champ sera rempli par le Repository (ou un appel séparé)
  final List<DailyStatus> history; 

  CI({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.status = CIStatus.operational,
    this.scope = CIScope.global,
    this.owner,
    this.attributes = const {},
    this.historyRetentionDays = 90, // Par défaut 90 jours
    this.history = const [],
  });
}
