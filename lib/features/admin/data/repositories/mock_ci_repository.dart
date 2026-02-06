import 'dart:math';
import '../../domain/entities/ci.dart';
import '../../domain/entities/dependency.dart';
import '../../domain/entities/daily_status.dart';
import '../../domain/entities/status_event.dart';
import '../../domain/repositories/ci_repository.dart';

/// Implémentation "Bouchon" (Mock) du Repository
class MockCIRepository implements CIRepository {
  
  // Simulation de la base de données (Fichiers)
  List<CI> _mockCIs = [];
  final List<Dependency> _mockDeps;
  final List<StatusEvent> _mockEvents = [];

  MockCIRepository() : _mockDeps = [] {
    _initData();
  }

  void _initData() {
    _mockDeps.addAll([
        // ... (Dépendances existantes inchangées) ...
        Dependency(id: 'd1', sourceCiId: 'app-checkout', targetCiId: 'tech-db-01'),
        Dependency(id: 'd2', sourceCiId: 'app-checkout', targetCiId: 'tech-api-01'),
        Dependency(id: 'd3', sourceCiId: 'biz-payment', targetCiId: 'app-checkout'),

        // --- LE COMPTE EST BON (RETAIL) ---
        Dependency(id: 'r1', sourceCiId: 'geste-vendre', targetCiId: 'app-caisse', impactWeight: 100),
        Dependency(id: 'r2', sourceCiId: 'app-caisse', targetCiId: 'app-paiement-cb', impactWeight: 50),
        Dependency(id: 'r3', sourceCiId: 'app-caisse', targetCiId: 'app-paiement-cash', impactWeight: 50),
        Dependency(id: 'r4', sourceCiId: 'app-paiement-cb', targetCiId: 'tech-auth-server', impactWeight: 100),
    ]);

    // ... (CIs inchangés) ... (Je copie-colle pour garder le contexte mais on pourrait optimiser)
    _mockCIs = [
      // TOUS LES CIs SONT OPERATIONAL PAR DÉFAUT (C'est l'événement qui change l'état)
      CI(id: 'tech-db-01', name: 'Database Customers', description: 'Oracle DB Server', type: CIType.technical, status: CIStatus.operational, scope: CIScope.global, history: _generateHistory(90)),
      CI(id: 'tech-api-01', name: 'API Gateway', description: 'Main Public Gateway', type: CIType.technical, status: CIStatus.operational, scope: CIScope.global, history: _generateHistory(90)),
      CI(id: 'app-checkout', name: 'Checkout Service', description: 'Microservice de paiement', type: CIType.application, status: CIStatus.operational, scope: CIScope.global, history: _generateHistory(90)),
      CI(id: 'biz-payment', name: 'Paiement en Ligne', description: 'Capacité à payer sur le site', type: CIType.businessService, status: CIStatus.operational, scope: CIScope.global, history: _generateHistory(90)),
      CI(id: 'biz-loyalty', name: 'Programme Fidélité', description: 'Gestion des points', type: CIType.businessService, status: CIStatus.operational, scope: CIScope.global, history: _generateHistory(90)),
      CI(id: 'geste-vendre', name: 'Vendre en Magasin', description: 'Processus de vente complet', type: CIType.businessService, scope: CIScope.local, history: _generateHistory(90)),
      CI(id: 'app-caisse', name: 'Passage Caisse', description: 'Logiciel de caisse', type: CIType.application, scope: CIScope.local, history: _generateHistory(90)),
      CI(id: 'app-paiement-cb', name: 'Paiement CB', description: 'Module CB', type: CIType.application, scope: CIScope.local, history: _generateHistory(90)),
      CI(id: 'app-paiement-cash', name: 'Paiement Espèces', description: 'Module Cash', type: CIType.application, scope: CIScope.local, history: _generateHistory(90)),
      CI(id: 'tech-auth-server', name: 'Serveur Auth Bancaire', description: 'Lien banque', type: CIType.technical, status: CIStatus.operational, scope: CIScope.global, history: _generateHistory(90)), 
    ];

    // --- INCIDENT FICTIF ---
    // Panne majeure sur le serveur d'Auth
    _mockEvents.add(StatusEvent(
      id: 'evt-001',
      title: 'Panne Système d\'Authentification Bancaire',
      description: 'Impossibilité de joindre le serveur bancaire pour les validations CB.',
      status: CIStatus.down,
      affectedCiId: 'tech-auth-server', // La cause racine
      startTime: DateTime.now().subtract(const Duration(hours: 2)), // Commencé il y a 2h
      posts: [
        EventPost(
          id: 'p1',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          author: 'System Monitor',
          message: 'Détection d\'un incident : Timeout sur les requêtes HTTPS vers BankAPI.',
          type: EventPostType.detection,
        ),
        EventPost(
          id: 'p2',
          date: DateTime.now().subtract(const Duration(hours: 1, minutes: 40)),
          author: 'Jean Admin',
          message: 'Les équipes réseau sont sur le coup. Le lien MPLS semble instable.',
          type: EventPostType.investigation,
        ),
        EventPost(
          id: 'p3',
          date: DateTime.now().subtract(const Duration(minutes: 30)),
          author: 'Marie Chef',
          message: 'Contournement possible : Bascule manuelle sur le lien de secours 4G des magasins en cours.',
          type: EventPostType.workaround,
        ),
      ],
    ));

    // --- INCIDENT FICTIF 2 (Concurrent) ---
    // Problème matériel sur les tiroirs caisse
    _mockEvents.add(StatusEvent(
      id: 'evt-002',
      title: 'Blocage Mécanique Tiroirs Caisses',
      description: 'Les tiroirs caisses ne s\'ouvrent plus automatiquement.',
      status: CIStatus.down, // CHANGEMENT : degraded -> down (Bloquant selon user)
      affectedCiId: 'app-paiement-cash', 
      startTime: DateTime.now().subtract(const Duration(minutes: 45)),
      posts: [
        EventPost(
          id: 'p2-1',
          date: DateTime.now().subtract(const Duration(minutes: 45)),
          author: 'Manager Magasin Paris',
          message: 'Impossible d\'ouvrir les caisses en espèce depuis la mise à jour firmware.',
          type: EventPostType.detection,
        ),
        EventPost(
          id: 'p2-2',
          date: DateTime.now().subtract(const Duration(minutes: 10)),
          author: 'Support Hardware',
          message: 'Le driver série semble en conflit. Rollback en cours.',
          type: EventPostType.investigation,
        ),
      ],
    ));
    
  }

  /// Génère un historique aléatoire
  List<DailyStatus> _generateHistory(int days) {
    final random = Random();
    final List<DailyStatus> history = [];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i + 1)); // J-1 à J-90
      
      // 95% de chance d'être vert
      double roll = random.nextDouble();
      CIStatus status = CIStatus.operational;
      
      if (roll > 0.98) {
        status = CIStatus.down; // 2% Panne
      } else if (roll > 0.95) {
        status = CIStatus.degraded; // 3% Dégradé
      }

      history.add(DailyStatus(date: date, status: status));
    }
    // On inverse pour avoir l'ordre chronologique (J-90 ... J-1)
    return history.reversed.toList();
  }

  @override
  Future<List<CI>> getAllCIs() async {
    // Simulation d'un délai réseau (Latence)
    await Future.delayed(const Duration(milliseconds: 500)); 
    return _mockCIs;
  }

  @override
  Future<List<Dependency>> getAllDependencies() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockDeps;
  }
  @override
  Future<List<StatusEvent>> getAllEvents() async {
    return _mockEvents;
  }
}
