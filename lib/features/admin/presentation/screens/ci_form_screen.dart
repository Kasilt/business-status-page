import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/ci.dart';
import '../../domain/repositories/ci_repository.dart';
import '../../../dashboard/presentation/providers/status_provider.dart';

class CIFormScreen extends StatefulWidget {
  final CI? ci; // Null = Création, sinon Édition

  const CIFormScreen({super.key, this.ci});

  @override
  State<CIFormScreen> createState() => _CIFormScreenState();
}

class _CIFormScreenState extends State<CIFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late CIType _selectedType;
  late CIScope _selectedScope;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ci?.name ?? '');
    _descController = TextEditingController(text: widget.ci?.description ?? '');
    _selectedType = widget.ci?.type ?? CIType.application;
    _selectedScope = widget.ci?.scope ?? CIScope.global;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repository = Provider.of<StatusProvider>(context, listen: false).repository;
      
      final ci = CI(
        // Si édition, on garde l'ID, sinon on en génère un nouveau
        id: widget.ci?.id ?? Uuid().v4(), 
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        scope: _selectedScope,
        status: widget.ci?.status ?? CIStatus.operational,
        history: widget.ci?.history ?? [],
      );

      if (widget.ci == null) {
        await repository.createCI(ci);
      } else {
        await repository.updateCI(ci);
      }

      if (mounted) {
        Navigator.pop(context, true); // Retourne true pour signaler succès
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ci == null ? 'Nouveau CI' : 'Modifier CI'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CIType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: CIType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                )).toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CIScope>(
                value: _selectedScope,
                decoration: const InputDecoration(labelText: 'Portée', border: OutlineInputBorder()),
                 items: CIScope.values.map((scope) => DropdownMenuItem(
                  value: scope,
                  child: Text(scope.name.toUpperCase()),
                )).toList(),
                onChanged: (v) => setState(() => _selectedScope = v!),
              ),
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
