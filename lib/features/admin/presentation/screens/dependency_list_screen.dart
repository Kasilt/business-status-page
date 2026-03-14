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
  Map<String, String> _ciNames = {};
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
      final cis = await repository.getAllCIs();
      
      final Map<String, String> ciNameMap = {};
      for (var ci in cis) {
         ciNameMap[ci.id] = ci.name;
      }

      setState(() {
        _dependencies = deps;
        _ciNames = ciNameMap;
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
    final repository = Provider.of<StatusProvider>(context, listen: false).repository;
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
      try {
        await repository.deleteDependency(dep.id);
        if (mounted) _loadDependencies();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
                final sourceName = _ciNames[dep.sourceCiId] ?? dep.sourceCiId;
                final targetName = _ciNames[dep.targetCiId] ?? dep.targetCiId;

                return ListTile(
                  leading: const Icon(Icons.link, color: Colors.blueGrey),
                  title: Text('$sourceName -> $targetName'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Impact: ${dep.impactWeight}%'),
                      if (dep.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Wrap(
                            spacing: 4.0,
                            children: dep.tags.map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            )).toList(),
                          ),
                        ),
                    ],
                  ),
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
