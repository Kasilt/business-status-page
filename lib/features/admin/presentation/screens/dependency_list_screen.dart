import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/dependency.dart';
import '../../domain/repositories/ci_repository.dart';
import '../../../dashboard/presentation/providers/status_provider.dart';
import 'dependency_form_screen.dart';

class DependencyListScreen extends StatefulWidget {
  const DependencyListScreen({super.key});

  @override
  State<DependencyListScreen> createState() => _DependencyListScreenState();
}

class _DependencyListScreenState extends State<DependencyListScreen> {
  List<Dependency> _dependencies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    setState(() => _isLoading = true);
    final repository = Provider.of<StatusProvider>(context, listen: false).repository;
    
    try {
      final deps = await repository.getAllDependencies();
      setState(() {
        _dependencies = deps;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
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
      // Il faut une méthode deleteDependency dans l'interface, on l'a ajoutée
      await repository.deleteDependency(dep.id);
      _loadDependencies();
    }
  }

  void _navigateToForm([Dependency? dep]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DependencyFormScreen(dependency: dep)),
    );

    if (result == true) {
      _loadDependencies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les Dépendances'),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _dependencies.length,
              itemBuilder: (context, index) {
                final dep = _dependencies[index];
                return ListTile(
                  leading: const Icon(Icons.link, color: Colors.blueGrey),
                  title: Text('${dep.sourceCiId} -> ${dep.targetCiId}'),
                  subtitle: Text('Impact: ${dep.impactWeight}%'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _navigateToForm(dep),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteDependency(dep),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
