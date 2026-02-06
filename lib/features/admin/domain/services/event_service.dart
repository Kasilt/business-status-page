import '../entities/ci.dart';
import '../entities/dependency.dart';
import '../entities/status_event.dart';

/// Service pour retrouver les événements impactant un CI
/// Analogie : Retrouver les tickets d'incidents (PMR) liés à un équipement
class EventService {
  
  /// Retourne la liste des événements ACTIFS qui impactent ce CI (lui-même ou ses enfants)
  List<StatusEvent> getEventsForCI(CI target, List<CI> allCIs, List<Dependency> allDeps, List<StatusEvent> allEvents) {
    // 1. Événements affectant directement ce CI
    final directEvents = allEvents.where((e) => e.affectedCiId == target.id && e.endTime == null).toList();

    // 2. Événements affectant les dépendances (Récursif)
    // On doit explorer l'arbre descendant
    // Qui sont mes enfants ?
    final myDependencies = allDeps.where((d) => d.sourceCiId == target.id).toList();
    
    final childEvents = <StatusEvent>[];

    for (var dep in myDependencies) {
      final childCI = allCIs.firstWhere((c) => c.id == dep.targetCiId, orElse: () => target);
      if (childCI.id == target.id) continue;

      // Appel récursif
      final subEvents = getEventsForCI(childCI, allCIs, allDeps, allEvents);
      childEvents.addAll(subEvents);
    }

    // Fusionner et dédoublonner (Set)
    final allImpactedEvents = {...directEvents, ...childEvents}.toList();
    
    // Trier par date du plus récent au plus ancien
    allImpactedEvents.sort((a, b) => b.startTime.compareTo(a.startTime));

    return allImpactedEvents;
  }
}
