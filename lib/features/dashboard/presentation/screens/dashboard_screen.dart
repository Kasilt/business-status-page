import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../admin/domain/entities/ci.dart';
import '../providers/status_provider.dart';
import 'event_timeline_screen.dart';
import '../../../admin/domain/entities/journey_map.dart';

import '../widgets/status_history_bar.dart';
import '../../../admin/domain/services/auth_service.dart';
import '../../../admin/presentation/screens/login_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';

/// L'écran principal du tableau de bord
/// Analogie AS/400 : Le membre Source DSPF
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  
  @override
  void initState() {
    super.initState();
    // Au lancement de l'écran (INZSR), on charge les données
    Future.microtask(() => 
      Provider.of<StatusProvider>(context, listen: false).loadDashboard()
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StatusProvider>(context);

    // Si on charge, on affiche un loader simple
    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Préparation des onglets
    final maps = provider.journeyMaps;
    final tabCount = 1 + maps.length; // Onglet Global + 1 par Journey Map

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Business Status One'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                  final user = AuthService().currentUser;
                  final provider = Provider.of<StatusProvider>(context, listen: false);
                  
                  if (user != null) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()))
                      .then((_) => provider.loadDashboard());
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()))
                      .then((_) => provider.loadDashboard());
                  }
                },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(text: 'Vue Globale', icon: Icon(Icons.public)),
              ...maps.map((m) => Tab(text: m.name, icon: const Icon(Icons.map))),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Onglet 1 : Vue Globale (Tous les services racines)
            _buildGlobalView(provider),
            
            // Onglets suivants : Vues par Journey Map
            ...maps.map((m) => _buildJourneyMapView(provider, m)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalView(StatusProvider provider) {
    final rootCIs = provider.cis.where((c) => c.type == CIType.businessService).toList();
    
    if (rootCIs.isEmpty) return const Center(child: Text("Aucun service disponible."));

    return ListView.builder(
      itemCount: rootCIs.length,
      itemBuilder: (context, index) {
        return _buildCITile(rootCIs[index], provider);
      },
    );
  }

  Widget _buildJourneyMapView(StatusProvider provider, JourneyMap map) {
    if (map.cis.isEmpty) {
      return const Center(child: Text("Aucun composant dans cette Journey Map."));
    }

    // On récupère les vrais objets CI dans l'ordre de la position définie
    final cisToDisplay = map.cis.map((jmci) {
        return provider.cis.firstWhere((c) => c.id == jmci.ciId, orElse: () => CI(id: '', name: 'Introuvable', description: '', type: CIType.application));
    }).where((c) => c.id.isNotEmpty).toList();

    return ListView.builder(
      itemCount: cisToDisplay.length,
      itemBuilder: (context, index) {
        // Dans une Journey Map, on n'affiche généralement pas l'arbre enfant,
        // on l'affiche "à plat" car c'est une vue de synthèse.
        // Si besoin d'afficher l'arbre, on pourrait utiliser _buildCITile sans modifier,
        // mais pour une Journey Map, forcer une tuile simple est souvent préféré.
        // Ici, on utilise _buildCITile normal. Modifiez si besoin d'une tuile "plate".
        return _buildFlatCITile(cisToDisplay[index], provider, index + 1);
      },
    );
  }

  Widget _buildFlatCITile(CI ci, StatusProvider provider, int stepNumber) {
    final status = provider.getEffectiveStatus(ci);
    final color = _getColorForStatus(status);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: color.withOpacity(0.5), width: 2)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          child: Text('$stepNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(ci.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Impact calculé automatiquement incluant l\'infrastructure invisible', style: const TextStyle(fontSize: 11)),
        trailing: _getStatusChip(status, context, ci, provider),
      ),
    );
  }

  /// Construit une tuile (Ligne) pour un CI, potentiellement dépliable
  /// Analogie AS/400 : Une ligne de Sous-Fichier avec option "+" (Fold/Drop)
  Widget _buildCITile(CI ci, StatusProvider provider) {
    // 1. Chercher les enfants de ce CI
    final children = provider.getChildren(ci);
    final status = provider.getEffectiveStatus(ci);
    final color = _getColorForStatus(status);
    
    // Widget de barre d'historique (Uniquement pour les services racines ou si demandé)
    // On l'affiche ici si l'historique est présent
    Widget? historyWidget;
    if (ci.history.isNotEmpty) {
       historyWidget = Padding(
         padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const Text('Historique 90 jours :', style: TextStyle(fontSize: 10, color: Colors.grey)),
             const SizedBox(height: 4),
             StatusHistoryBar(history: ci.history),
           ],
         ),
       );
    }

    // Contenu principal de la tuile
    Widget tileContent;

    // Si pas d'enfant, c'est une feuille (Leaf) -> Simple ListTile
    if (children.isEmpty) {
      tileContent = ListTile(
          leading: Icon(_getIconForType(ci.type), color: color),
          title: Text(ci.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${ci.description} [${ci.scope.name.toUpperCase()}]'),
          trailing: _getStatusChip(status, context, ci, provider),
        );
    } else {
      // Sinon, c'est un Noeud (Node) -> ExpansionTile
      tileContent = ExpansionTile(
        leading: Icon(_getIconForType(ci.type), color: color),
        title: Text(ci.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${ci.description} [${ci.scope.name.toUpperCase()}]'),
        trailing: _getStatusChip(status, context, ci, provider), // Chip à droite (taille naturelle)
        children: children.map<Widget>((child) => _buildCITile(child, provider)).toList(), // Récursion visuelle
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: color.withOpacity(0.5), width: 1.5)),
      child: Column(
        children: [
          tileContent,
          if (historyWidget != null) historyWidget,
        ],
      ),
    );
  }
// ...

  IconData _getIconForType(CIType type) {
    switch (type) {
      case CIType.technical: return Icons.storage; // Serveur
      case CIType.application: return Icons.apps; // Logiciel
      case CIType.businessService: return Icons.shopping_bag; // Service métier
    }
  }

  Color _getColorForStatus(CIStatus status) {
    switch (status) {
      case CIStatus.operational: return Colors.green;
      case CIStatus.degraded: return Colors.orange;
      case CIStatus.down: return Colors.red;
      case CIStatus.maintenance: return Colors.blue;
    }
  }

  Widget _getStatusChip(CIStatus status, BuildContext context, CI ci, StatusProvider provider) {
    String label;
    Color color;

    // TODO: Prévoir l'internationalisation (i18n) pour ces libellés (Anglais: Operational, Degraded, Outage, Maintenance)
    switch (status) {
      case CIStatus.operational: label = 'Opérationnel'; color = Colors.green; break;
      case CIStatus.degraded: label = 'Dégradé'; color = Colors.orange; break;
      case CIStatus.down: label = 'Panne'; color = Colors.red; break;
      case CIStatus.maintenance: label = 'Maintenance'; color = Colors.blue; break;
    }

    return InkWell(
      onTap: () {
        // Navigation vers la timeline si événements
        final events = provider.getEventsForCI(ci);
        
        if (events.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun incident déclaré')));
          return;
        }

        if (events.length == 1) {
          // Cas simple : 1 seul incident -> Navigation directe
           Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventTimelineScreen(event: events.first)),
          );
        } else {
          // Cas multiple : Choix de l'incident
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incidents en cours (${events.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...events.map((event) => ListTile(
                      leading: Icon(Icons.warning, color: _getColorForStatus(event.status)),
                      title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Depuis: ${_formatDate(event.startTime)}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context); // Fermer la modale
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EventTimelineScreen(event: event)),
                        );
                      },
                    )).toList(),
                  ],
                ),
              );
            },
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            // Indique qu'il y a un lien cliquable si événements
            if (provider.getEventsForCI(ci).length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.list, size: 16, color: color),
              )
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }
}
