import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/journey_map.dart';
import '../../../dashboard/presentation/providers/status_provider.dart';
import 'journey_map_builder_screen.dart';

class JourneyMapListScreen extends StatefulWidget {
  const JourneyMapListScreen({super.key});

  @override
  State<JourneyMapListScreen> createState() => _JourneyMapListScreenState();
}

class _JourneyMapListScreenState extends State<JourneyMapListScreen> {
  List<JourneyMap> _maps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaps();
  }

  Future<void> _loadMaps() async {
    setState(() => _isLoading = true);
    final repository = Provider.of<StatusProvider>(context, listen: false).repository;
    
    try {
      final maps = await repository.getAllJourneyMaps();
      if (mounted) {
        setState(() {
          _maps = maps;
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

  Future<void> _deleteMap(JourneyMap map) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la Journey Map "${map.name}" ?'),
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
      await repository.deleteJourneyMap(map.id);
      _loadMaps();
    }
  }

  void _navigateToForm([JourneyMap? map]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JourneyMapBuilderScreen(journeyMap: map)),
    );

    if (result == true) {
      _loadMaps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Journey Maps'),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        tooltip: 'Créer une Journey Map',
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _maps.isEmpty
              ? const Center(child: Text('Aucune Journey Map. Créez-en une !'))
              : ListView.builder(
                  itemCount: _maps.length,
                  itemBuilder: (context, index) {
                    final map = _maps[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Icon(Icons.map, color: Colors.white),
                        ),
                        title: Text(map.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${map.cis.length} composants liés\n${map.description ?? ''}'),
                        isThreeLine: map.description != null && map.description!.isNotEmpty,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Modifier',
                              onPressed: () => _navigateToForm(map),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Supprimer',
                              onPressed: () => _deleteMap(map),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToForm(map),
                      ),
                    );
                  },
                ),
    );
  }
}
