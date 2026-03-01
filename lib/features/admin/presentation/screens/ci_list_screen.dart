import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/ci.dart';
import '../../domain/repositories/ci_repository.dart';
import '../../../dashboard/presentation/providers/status_provider.dart'; // Pour réutiliser le repository injecté
import 'ci_form_screen.dart';
import 'ci_detail_screen.dart';

class CIListScreen extends StatefulWidget {
  const CIListScreen({super.key});

  @override
  State<CIListScreen> createState() => _CIListScreenState();
}

class _CIListScreenState extends State<CIListScreen> {
  List<CI> _cis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCIs();
  }

  Future<void> _loadCIs() async {
    setState(() => _isLoading = true);
    // On récupère le repository via le StatusProvider (ou on pourrait l'injecter autrement)
    final repository = Provider.of<StatusProvider>(context, listen: false).repository;
    
    // TODO: Ajouter une méthode 'getAllCIs' spécifique Admin si besoin de bypasser le cache
    // Pour l'instant on utilise celle du repository direct
    
    // cast hack car StatusProvider expose pas directement le repo en public clean parfois, mais ici on l'a passé au constructeur du provider
    // On va supposer qu'on peut l'atteindre. Sinon il faudra un AdminProvider dédié.
    // Pour simplifier, on va instancier un repo ou le récupérer.
    // Mieux : Utiliser un FutureBuilder sur le repository.
    
    try {
      final cis = await (repository as dynamic).getAllCIs(); // Cast dynamique si le type n'est pas strict
      setState(() {
        _cis = cis;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _deleteCI(CI ci) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${ci.name} ?'),
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
      // Appel deleteCI (cast car l'interface de base l'a peut-être pas encore selon le fichier vu)
      // Mais on l'a ajouté à l'interface donc c'est bon.
      await repository.deleteCI(ci.id); 
      _loadCIs(); // Rechargement
    }
  }

  void _navigateToForm([CI? ci]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CIFormScreen(ci: ci)),
    );

    if (result == true) {
      _loadCIs(); // Rafraîchir si sauvegarde effectuée
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des CIs'),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _cis.length,
              itemBuilder: (context, index) {
                final ci = _cis[index];
                return ListTile(
                  leading: Icon(_getIconForType(ci.type), color: Colors.indigo),
                  title: Text(ci.name),
                  subtitle: Text('${ci.type.name} - ${ci.scope.name}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CIDetailScreen(ci: ci),
                      ),
                    ).then((_) => _loadCIs()); // Rafraîchit au retour au cas où modifié
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _navigateToForm(ci),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCI(ci),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  IconData _getIconForType(CIType type) {
    switch (type) {
      case CIType.technical: return Icons.storage;
      case CIType.application: return Icons.apps;
      case CIType.businessService: return Icons.shopping_bag;
    }
  }
}
