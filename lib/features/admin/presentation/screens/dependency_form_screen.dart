import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/ci.dart';
import '../../domain/entities/dependency.dart';
import '../../domain/repositories/ci_repository.dart';
import '../../../dashboard/presentation/providers/status_provider.dart';

class DependencyFormScreen extends StatefulWidget {
  final Dependency? dependency; // Null = Création
  final String? prefilledSourceId;
  final String? prefilledTargetId;

  const DependencyFormScreen({
    super.key, 
    this.dependency,
    this.prefilledSourceId,
    this.prefilledTargetId,
  });

  @override
  State<DependencyFormScreen> createState() => _DependencyFormScreenState();
}

class _DependencyFormScreenState extends State<DependencyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _sourceCiId;
  String? _targetCiId;
  int _impactWeight = 100;
  List<CI> _cis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _sourceCiId = widget.dependency?.sourceCiId ?? widget.prefilledSourceId;
    _targetCiId = widget.dependency?.targetCiId ?? widget.prefilledTargetId;
    _impactWeight = widget.dependency?.impactWeight ?? 100;
    _loadCIs();
  }

  Future<void> _loadCIs() async {
    final repository = Provider.of<StatusProvider>(context, listen: false).repository;
    try {
      final cis = await repository.getAllCIs();
      setState(() {
        _cis = cis;
        _isLoading = false;
      });
    } catch (e) {
      // Gérer erreur
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sourceCiId == _targetCiId) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Source et Cible doivent être différents')));
       return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = Provider.of<StatusProvider>(context, listen: false).repository;
      
      final dep = Dependency(
        // ID généré par la DB si création, sinon existant (Note: updateDependency utilise l'ID)
        // Attention: Supabase génère l'ID, donc en création on peut passer un ID temporaire ou null si l'entité le permettais
        // Mais notre entité Dart 'Dependency' a un 'id' String requis.
        // Solution simple : On passe '0' en création et le repository l'ignorera lors de l'insert.
        id: widget.dependency?.id ?? '0', 
        sourceCiId: _sourceCiId!,
        targetCiId: _targetCiId!,
        impactWeight: _impactWeight,
        buFilter: null, // TODO: Ajouter support BU Filter plus tard
      );

      if (widget.dependency == null) {
        await repository.createDependency(dep);
      } else {
        await repository.updateDependency(dep);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dependency == null ? 'Nouvelle Dépendance' : 'Modifier Dépendance'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _sourceCiId,
                decoration: const InputDecoration(labelText: 'CI Parent (Source)', border: OutlineInputBorder()),
                items: _cis.map((ci) => DropdownMenuItem(
                  value: ci.id,
                  child: Text(ci.name),
                )).toList(),
                onChanged: (v) => setState(() => _sourceCiId = v),
                validator: (v) => v == null ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              const Icon(Icons.arrow_downward, size: 32, color: Colors.grey),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _targetCiId,
                decoration: const InputDecoration(labelText: 'CI Enfant (Cible)', border: OutlineInputBorder()),
                items: _cis.map((ci) => DropdownMenuItem(
                  value: ci.id,
                  child: Text(ci.name),
                )).toList(),
                onChanged: (v) => setState(() => _targetCiId = v),
                validator: (v) => v == null ? 'Requis' : null,
              ),
              const SizedBox(height: 32),
              Text('Poids de l\'impact: $_impactWeight%', style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: _impactWeight.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$_impactWeight%',
                onChanged: (v) => setState(() => _impactWeight = v.round()),
              ),
              const Text('Si la Cible tombe, le Parent est impacté à ce niveau.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
