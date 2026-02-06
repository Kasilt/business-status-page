import '../entities/ci.dart';
import '../entities/dependency.dart';
import '../entities/business_unit.dart';

/// Service de calcul d'impact
/// Analogie AS/400 : Programme de traitement (Calcul de prix, de besoin...)
class ImpactService {
  
  /// Calcule le statut effectif d'un CI pour un contexte donné
  /// Analogie : Appel du main PGM de calcul avec paramètres
  CIStatus calculateStatus(CI target, List<CI> allCIs, List<Dependency> allDeps, {BusinessUnit? contextBu, Map<String, CIStatus>? activeEventImpacts}) {
    
    // 0. Statut intrinsèque (Overrides par événement ?)
    CIStatus selfStatus = target.status;
    if (activeEventImpacts != null && activeEventImpacts.containsKey(target.id)) {
      selfStatus = activeEventImpacts[target.id]!;
    }

    // 1. Trouver les enfants (Dépendances)
    final dependencies = allDeps.where((d) => d.sourceCiId == target.id).toList();

    if (dependencies.isEmpty) {
      return selfStatus; // Feuille de l'arbre
    }

    // 2. Calcul des dégâts cumulés
    double currentDamage = 0.0;
    
    // Dégâts initiaux du CI lui-même
    if (selfStatus == CIStatus.down) {
      currentDamage = 100.0;
    } else if (selfStatus == CIStatus.degraded) {
      currentDamage = 30.0;
    }

    for (var dep in dependencies) {
      // Filtrage par BU
      if (contextBu != null && dep.buFilter != null && !dep.buFilter!.contains(contextBu.code)) {
        continue;
      }

      try {
        final childCI = allCIs.firstWhere((c) => c.id == dep.targetCiId);

        // Appel Récursif
        final childStatus = calculateStatus(childCI, allCIs, allDeps, contextBu: contextBu, activeEventImpacts: activeEventImpacts);

        // Calcul des dégâts apportés par cette dépendance
        if (childStatus == CIStatus.down) {
          currentDamage += dep.impactWeight;
        } else if (childStatus == CIStatus.degraded) {
          currentDamage += (dep.impactWeight * 0.5);
        }

      } catch (e) {
        continue; 
      }
    }

    // 3. Détermination du statut final
    if (currentDamage >= 100.0) {
      return CIStatus.down;
    } else if (currentDamage > 0.0) {
      return CIStatus.degraded;
    } else {
      return CIStatus.operational;
    }
  }

  CIStatus _getWorst(CIStatus s1, CIStatus s2) {
    if (s1 == CIStatus.down || s2 == CIStatus.down) return CIStatus.down;
    if (s1 == CIStatus.degraded || s2 == CIStatus.degraded) return CIStatus.degraded;
    if (s1 == CIStatus.maintenance || s2 == CIStatus.maintenance) return CIStatus.maintenance;
    return CIStatus.operational;
  }
}
