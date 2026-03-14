import 'package:flutter/material.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';
import 'tag_form_screen.dart';

class TagListScreen extends StatefulWidget {
  final TagRepository repository;

  const TagListScreen({super.key, required this.repository});

  @override
  State<TagListScreen> createState() => _TagListScreenState();
}

class _TagListScreenState extends State<TagListScreen> {
  List<Tag> _tags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final tags = await widget.repository.getAllTags();
      if (mounted) {
        setState(() {
          _tags = tags;
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

  Future<void> _deleteTag(Tag tag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Supprimer le tag "${tag.label}" ?'),
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
      await widget.repository.deleteTag(tag.id);
      _loadTags();
    }
  }

  void _navigateToForm([Tag? tag]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TagFormScreen(repository: widget.repository, tag: tag)),
    );

    if (result == true) {
      _loadTags();
    }
  }
  
  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // Add alpha
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les Tags (Scope)'),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                final tag = _tags[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _parseColor(tag.color),
                    child: const Icon(Icons.label, color: Colors.white, size: 16),
                  ),
                  title: Text(tag.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(tag.color),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _navigateToForm(tag),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTag(tag),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
