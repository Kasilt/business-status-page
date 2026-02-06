import 'package:flutter/material.dart';
import '../../../admin/domain/entities/ci.dart';
import '../../../admin/domain/entities/dependency.dart';
import '../../../admin/domain/entities/status_event.dart';
import '../../../admin/domain/repositories/ci_repository.dart';
import '../../../admin/domain/services/impact_service.dart';
import '../../../admin/domain/services/event_service.dart';

class StatusProvider extends ChangeNotifier {
  final CIRepository repository;
  final ImpactService _impactService = ImpactService();
  final EventService _eventService = EventService();

  List<CI> _cis = [];
  List<Dependency> _dependencies = [];
  List<StatusEvent> _events = []; // Liste des événements chargés
  bool _isLoading = false;

  // Cache des statuts calculés (Map<CiId, Status>)
  Map<String, CIStatus> _calculatedStatus = {};

  List<CI> get cis => _cis;
  bool get isLoading => _isLoading;

  StatusProvider({required this.repository});
  
  /// Charge les données et recalcule l'impact
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Chargement parallèle (Optimisation)
      final results = await Future.wait([
        repository.getAllCIs(),
        repository.getAllDependencies(),
        repository.getAllEvents(),
      ]);
      
      _cis = results[0] as List<CI>;
      _dependencies = results[1] as List<Dependency>;
      _events = results[2] as List<StatusEvent>;

      // Calcul de l'impact pour chaque CI (Scope Global par défaut pour l'instant)
      _recalculateImpacts();

    } catch (e) {
      print("Erreur de chargement: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _recalculateImpacts() {
    _calculatedStatus.clear();
    
    // 1. Construire la Map des impacts directs liés aux événements
    // Pour chaque incident en cours (pas fini), le CI concerné prend le statut de l'incident.
    final Map<String, CIStatus> activeEventImpacts = {};
    for (var event in _events) {
      if (event.endTime == null) {
        // En cours
        // Si plusieurs événements touchent le même CI, on garde le pire statut (optionnel, mais prudent)
        if (activeEventImpacts.containsKey(event.affectedCiId)) {
          // Logique de pire statut si conflit
          // ... Simplification: On écrase pour l'instant ou on pourrait utiliser _impactService._getWorst
          // mais _getWorst est privée. Pour l'instant, premier arrivé ou écrasement.
          // Disons que l'événement le plus récent (dernier de la liste) gagne ou le pire.
          // TODO: Gérer la priorité entre événements.
          activeEventImpacts[event.affectedCiId] = event.status; 
        } else {
          activeEventImpacts[event.affectedCiId] = event.status;
        }
      }
    }

    for (var ci in _cis) {
      // TODO: Passer le contexte BU si on a un filtre actif
      final status = _impactService.calculateStatus(ci, _cis, _dependencies, activeEventImpacts: activeEventImpacts);
      _calculatedStatus[ci.id] = status;
    }
  }

  /// Récupère le statut (Calculé ou Brut si erreur) pour l'affichage
  CIStatus getEffectiveStatus(CI ci) {
    return _calculatedStatus[ci.id] ?? ci.status;
  }

  /// Récupère les événements impactant ce CI
  List<StatusEvent> getEventsForCI(CI ci) {
    return _eventService.getEventsForCI(ci, _cis, _dependencies, _events);
  }

  /// Récupère la liste des enfants directs d'un CI (Utilisé pour l'affichage Arbre)
  List<CI> getChildren(CI parent) {
    // 1. Trouver les dépendances où parent est la SOURCE (Car parent dépend de l'enfant dans le sens de l'impact ?)
    // ATTENTION : Ma définition de Dependency est : source dépend de target.
    // Donc si je veux afficher "De qui je dépend" (Mes sous-composants), je cherche les dépendances où je suis la SOURCE.
    // Ex: Vendre (Source) dépend de Caisse (Target).
    // Donc Caisse est un SOUS-COMPOSANT de Vendre.
    final List<Dependency> directDeps = _dependencies.where((d) => d.sourceCiId == parent.id).toList();
    
    // 2. Mapper vers les objets CI
    return directDeps.map((Dependency d) => _cis.firstWhere((c) => c.id == d.targetCiId, orElse: () => parent)).where((c) => c != parent).toList();
  }
}
