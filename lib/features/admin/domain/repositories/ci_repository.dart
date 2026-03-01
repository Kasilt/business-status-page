import '../entities/ci.dart';
import '../entities/dependency.dart';
import '../entities/status_event.dart';
import '../entities/journey_map.dart';

/// Interface du Repository
/// Analogie AS/400 : C'est le Prototype (PR) de vos procédures d'accès aux données.
/// On définit les "commandes" disponibles (Lire, Écrire) sans dire s'il s'agit
/// d'un fichier physique, logique, ou SQL.
abstract class CIRepository {
  /// Récupère la liste complète des CIs (SetLL + Read Loop)
  Future<List<CI>> getAllCIs();

  /// Récupère toutes les dépendances
  Future<List<Dependency>> getAllDependencies();

  Future<List<StatusEvent>> getAllEvents(); // Ajout pour récupérer les incidents

  // Write operations
  Future<void> createCI(CI ci);
  Future<void> updateCI(CI ci);
  Future<void> deleteCI(String id);

  // Dependency operations
  Future<void> createDependency(Dependency dep);
  Future<void> updateDependency(Dependency dep); // Pour modifier le poids ou le filtre
  Future<void> deleteDependency(String id);

  // Journey Map operations
  Future<List<JourneyMap>> getAllJourneyMaps();
  Future<void> createJourneyMap(JourneyMap jm);
  Future<void> updateJourneyMap(JourneyMap jm);
  Future<void> deleteJourneyMap(String id);
}
