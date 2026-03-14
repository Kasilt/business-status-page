import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/status_event.dart';
import '../../domain/entities/ci.dart';
import '../../../dashboard/presentation/providers/status_provider.dart';
import 'event_form_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<StatusEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final repository = Provider.of<StatusProvider>(context, listen: false).repository;
    
    try {
      final events = await repository.getAllEvents();
      // Sort by start time descending
      events.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _deleteEvent(StatusEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cet événement : ' + event.title + ' ?'),
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
      try {
        await repository.deleteEvent(event.id); 
        _loadEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Événement supprimé avec succès')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToForm([StatusEvent? event]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventFormScreen(event: event)),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  Color _getStatusColor(CIStatus status) {
    switch (status) {
      case CIStatus.operational: return Colors.green;
      case CIStatus.degraded: return Colors.orange;
      case CIStatus.down: return Colors.red;
      case CIStatus.maintenance: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Événements'),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('Aucun événement trouvé.'))
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    final isClosed = event.stage == IncidentStage.closed;
                    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(event.status),
                          child: Icon(
                            isClosed ? Icons.check_circle : Icons.warning,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          event.title,
                          style: TextStyle(
                            decoration: isClosed ? TextDecoration.lineThrough : null,
                            color: isClosed ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${event.stage.name.toUpperCase()} - Début: ${dateFormat.format(event.startTime)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (event.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: event.tags.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(tag, style: const TextStyle(fontSize: 10)),
                                  )).toList(),
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _navigateToForm(event),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEvent(event),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
