import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/ci.dart';
import '../../domain/entities/dependency.dart';
import '../../../dashboard/presentation/providers/status_provider.dart';
import 'dependency_form_screen.dart';
import 'ci_form_screen.dart';

class CIDetailScreen extends StatefulWidget {
  final CI ci;

  const CIDetailScreen({super.key, required this.ci});

  @override
  State<CIDetailScreen> createState() => _CIDetailScreenState();
}

class _CIDetailScreenState extends State<CIDetailScreen> {
  bool _isLoading = true;
  List<Dependency> _incomingDependencies = []; // CIs qui dépendent de ce CI (Target = This CI)
  List<Dependency> _outgoingDependencies = []; // CIs dont dépend ce CI (Source = This CI)
  
  // Pour afficher les noms des CIs liés (map id -> nom)
  Map<String, String> _ciNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repository = Provider.of<StatusProvider>(context, listen: false).repository;
    
    try {
      // 1. Charger toutes les dépendances (ou filtrées si le repo le permettait, ici on filtre en mémoire pour aller vite)
      final allDeps = await repository.getAllDependencies();
      
      // 2. Filtrer
      final incoming = allDeps.where((d) => d.targetCiId == widget.ci.id).toList();
      final outgoing = allDeps.where((d) => d.sourceCiId == widget.ci.id).toList();

      // 3. Charger les noms pour un affichage plus convivial
      final allCIs = await repository.getAllCIs();
      final Map<String, String> names = {};
      for (var c in allCIs) {
        names[c.id] = c.name;
      }

      if (mounted) {
        setState(() {
          _incomingDependencies = incoming;
          _outgoingDependencies = outgoing;
          _ciNames = names;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _addDependency({required bool isOutgoing}) async {
    // Si isOutgoing: ce CI est la source. Si Incoming: ce CI est la cible.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DependencyFormScreen(
          prefilledSourceId: isOutgoing ? widget.ci.id : null,
          prefilledTargetId: !isOutgoing ? widget.ci.id : null,
        ),
      ),
    );

    if (result == true) {
      _loadData(); // Rafraîchir les listes
    }
  }

  Future<void> _deleteDependency(Dependency dep) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Supprimer cette dépendance ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer')
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repository = Provider.of<StatusProvider>(context, listen: false).repository;
      await repository.deleteDependency(dep.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail: ${widget.ci.name}'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier le CI',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CIFormScreen(ci: widget.ci)),
              );
              // Si on modifie le CI (nom, type...), idéalement on devrait le recharger ici.
              // Mais l'écran parent raffraichira la liste, donc on peut se contenter d'un simple retour.
              if (result == true) {
                  // Optionnel: remonter l'état ou recharger
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 24),
                  
                  // Section: Dépendances Entrantes
                  _buildSectionTitle(
                    'Dépendances Entrantes (Qui dépend de moi ?)', 
                    Icons.arrow_downward, 
                    Colors.orange,
                    onAdd: () => _addDependency(isOutgoing: false),
                  ),
                  _buildDependencyList(_incomingDependencies, isIncoming: true),
                  
                  const SizedBox(height: 24),
                  
                  // Section: Dépendances Sortantes
                  _buildSectionTitle(
                    'Dépendances Sortantes (De quoi je dépends ?)', 
                    Icons.arrow_upward, 
                    Colors.green,
                    onAdd: () => _addDependency(isOutgoing: true),
                  ),
                  _buildDependencyList(_outgoingDependencies, isIncoming: false),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            _buildInfoRow('Type:', widget.ci.type.name.toUpperCase()),
            const SizedBox(height: 8),
            _buildInfoRow('Portée:', widget.ci.scope.name.toUpperCase()),
            const SizedBox(height: 8),
            _buildInfoRow('Description:', widget.ci.description),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color, {required VoidCallback onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.blue),
          onPressed: onAdd,
          tooltip: 'Ajouter',
        )
      ],
    );
  }

  Widget _buildDependencyList(List<Dependency> deps, {required bool isIncoming}) {
    if (deps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('Aucune dépendance configurée.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      );
    }

    return Card(
      elevation: 1,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: deps.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final dep = deps[index];
          // Si Entrante: on affiche la SOURCE (qui a besoin de moi).
          // Si Sortante: on affiche la CIBLE (de qui j'ai besoin).
          final linkedId = isIncoming ? dep.sourceCiId : dep.targetCiId;
          final linkedName = _ciNames[linkedId] ?? linkedId;
          
          return ListTile(
             leading: Icon(isIncoming ? Icons.login : Icons.logout, size: 20, color: Colors.grey),
             title: Text(linkedName, style: const TextStyle(fontWeight: FontWeight.bold)),
             subtitle: Text('Impact: ${dep.impactWeight}%'),
             trailing: IconButton(
               icon: const Icon(Icons.delete_outline, color: Colors.red),
               onPressed: () => _deleteDependency(dep),
             ),
             onTap: () {
               // Pourrait naviguer vers le formulaire de la dépendance pour édition
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DependencyFormScreen(dependency: dep)),
               ).then((value) {
                 if(value == true) _loadData();
               });
             },
          );
        },
      ),
    );
  }
}
