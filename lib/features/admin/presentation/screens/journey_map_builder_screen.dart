import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/journey_map.dart';
import '../../domain/entities/ci.dart';
import '../../../dashboard/presentation/providers/status_provider.dart';

class JourneyMapBuilderScreen extends StatefulWidget {
  final JourneyMap? journeyMap;

  const JourneyMapBuilderScreen({super.key, this.journeyMap});

  @override
  State<JourneyMapBuilderScreen> createState() => _JourneyMapBuilderScreenState();
}

class _JourneyMapBuilderScreenState extends State<JourneyMapBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  
  // Liste des CIs actuellement liés à cette map
  List<JourneyMapCI> _linkedCIs = [];
  
  // Liste de tous les CIs disponibles dans le système
  List<CI> _allCIs = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.journeyMap?.name ?? '');
    _descController = TextEditingController(text: widget.journeyMap?.description ?? '');
    if (widget.journeyMap != null) {
      _linkedCIs = List.from(widget.journeyMap!.cis);
    }
    _loadAllCIs();
  }

  Future<void> _loadAllCIs() async {
    final repository = Provider.of<StatusProvider>(context, listen: false).repository;
    try {
      final cis = await repository.getAllCIs();
      if (mounted) {
        setState(() {
          _allCIs = cis;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement CIs: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Mettre à jour les positions avant de sauvegarder
    for (int i = 0; i < _linkedCIs.length; i++) {
        // En Dart, on ne peut pas modifier un attribut final directement.
        // On recrée l'objet avec la bonne position si le modèle l'exige, 
        // ou on s'assure que la liste est ordonnée et on recrée les objets à la volée.
        _linkedCIs[i] = JourneyMapCI(
          journeyMapId: widget.journeyMap?.id ?? '', // Sera corrigé par l'ID final
          ciId: _linkedCIs[i].ciId,
          position: i,
        );
    }

    setState(() => _isSaving = true);

    try {
      final repository = Provider.of<StatusProvider>(context, listen: false).repository;
      
      final jm = JourneyMap(
        id: widget.journeyMap?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        cis: _linkedCIs,
      );

      // On s'assure que les IDs de la carte sont injectés dans les CIs liés pour une nouvelle Map
      if (widget.journeyMap == null) {
          final updatedLinkedCis = jm.cis.map((jmci) => JourneyMapCI(
            journeyMapId: jm.id, 
            ciId: jmci.ciId, 
            position: jmci.position
          )).toList();
          
          final jmToCreate = JourneyMap(id: jm.id, name: jm.name, description: jm.description, cis: updatedLinkedCis);
          await repository.createJourneyMap(jmToCreate);
      } else {
          await repository.updateJourneyMap(jm);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur sauvegarde: $e')));
      }
    }
  }

  void _addCI(CI ci) {
    if (_linkedCIs.any((jmci) => jmci.ciId == ci.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ce composant est déjà dans la Journey Map.')));
      return;
    }
    
    setState(() {
      _linkedCIs.add(JourneyMapCI(
        journeyMapId: widget.journeyMap?.id ?? '', 
        ciId: ci.id,
        position: _linkedCIs.length,
      ));
    });
  }

  void _removeCI(int index) {
    setState(() {
      _linkedCIs.removeAt(index);
    });
  }

  void _reorderCIs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _linkedCIs.removeAt(oldIndex);
      _linkedCIs.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.journeyMap == null ? 'Nouvelle Journey Map' : 'Éditer Journey Map'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Enregistrer',
            onPressed: _isSaving || _isLoading ? null : _save,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne de gauche : Formulaire & Liste des items liés (Reorderable)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMapFormCard(),
                      const SizedBox(height: 16),
                      Text('Composants de la Journey Map', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      const Text('Faites glisser les éléments pour définir l\'ordre chronologique métier.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: _linkedCIs.isEmpty
                            ? const Center(child: Text('Aucun composant. Ajoutez-en depuis la liste à droite.', style: TextStyle(fontStyle: FontStyle.italic)))
                            : ReorderableListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _linkedCIs.length,
                                onReorder: _reorderCIs,
                                itemBuilder: (context, index) {
                                  final jmci = _linkedCIs[index];
                                  final ci = _allCIs.firstWhere((c) => c.id == jmci.ciId, orElse: () => CI(id: '?', name: 'Inconnu', description: '', type: CIType.application));
                                  return ListTile(
                                    key: ValueKey(jmci.ciId),
                                    leading: CircleAvatar(child: Text('${index + 1}')),
                                    title: Text(ci.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(ci.type.name),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () => _removeCI(index),
                                    ),
                                  );
                                },
                              ),
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Colonne de droite : Liste de tous les CIs pour ajout rapide
                Expanded(
                  flex: 1,
                  child: Card(
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Text('Composants Disponibles', style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _allCIs.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final ci = _allCIs[index];
                              final isAlreadyInMap = _linkedCIs.any((jmci) => jmci.ciId == ci.id);
                              
                              return ListTile(
                                enabled: !isAlreadyInMap,
                                leading: Icon(isAlreadyInMap ? Icons.check_circle : Icons.add_circle_outline, color: isAlreadyInMap ? Colors.green : Colors.blue),
                                title: Text(ci.name, style: TextStyle(color: isAlreadyInMap ? Colors.grey : Colors.black)),
                                subtitle: Text(ci.type.name, style: const TextStyle(fontSize: 12)),
                                onTap: isAlreadyInMap ? null : () => _addCI(ci),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
    );
  }

  Widget _buildMapFormCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom de la Journey Map', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description (Optionnelle)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
