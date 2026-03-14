import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/status_event.dart';
import '../../domain/entities/ci.dart';
import '../../../dashboard/presentation/providers/status_provider.dart';

class EventFormScreen extends StatefulWidget {
  final StatusEvent? event;

  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _tagsController;
  late TextEditingController _externalLinkController;
  late TextEditingController _externalRefController;
  
  late CIStatus _selectedStatus;
  late IncidentStage _selectedStage;
  String? _selectedCiId;
  String? _currentEventId;
  
  late DateTime _startTime;
  DateTime? _endTime;
  
  List<CI> _availableCIs = [];
  List<EventPost> _posts = [];
  bool _isLoading = false;
  bool _isLoadingDropdowns = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descController = TextEditingController(text: widget.event?.description ?? '');
    _tagsController = TextEditingController(text: widget.event?.tags.join(', ') ?? '');
    _externalLinkController = TextEditingController(text: widget.event?.externalLink ?? '');
    _externalRefController = TextEditingController(text: widget.event?.externalRef ?? '');
    
    _selectedStatus = widget.event?.status ?? CIStatus.down;
    _selectedStage = widget.event?.stage ?? IncidentStage.detection;
    _selectedCiId = widget.event?.affectedCiId;
    _currentEventId = widget.event?.id;
    
    _startTime = widget.event?.startTime ?? DateTime.now();
    _endTime = widget.event?.endTime;
    
    _posts = widget.event?.posts.toList() ?? [];
    
    _loadCIs();
  }
  
  Future<void> _loadCIs() async {
    final repository = Provider.of<StatusProvider>(context, listen: false).repository;
    try {
      final cis = await repository.getAllCIs();
      setState(() {
        _availableCIs = cis;
        _isLoadingDropdowns = false;
        if (_selectedCiId == null && cis.isNotEmpty) {
           _selectedCiId = cis.first.id;
        }
      });
    } catch (e) {
      setState(() => _isLoadingDropdowns = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _externalLinkController.dispose();
    _externalRefController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startTime : (_endTime ?? DateTime.now());
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    
    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      
      if (pickedTime != null) {
        setState(() {
          final newDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          
          if (isStart) {
            _startTime = newDateTime;
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _addPost() async {
    final messageController = TextEditingController();
    EventPostType selectedType = EventPostType.info;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter une note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EventPostType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type de note'),
                items: EventPostType.values.map((v) => DropdownMenuItem(
                  value: v, 
                  child: Text(v.name)
                )).toList(),
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            TextButton(
              onPressed: () => Navigator.pop(context, true), 
              child: const Text('Ajouter')
            ),
          ],
        )
      )
    );
    
    if (result == true && messageController.text.isNotEmpty) {
      setState(() {
        _posts.insert(0, EventPost(
          id: const Uuid().v4(),
          date: DateTime.now(),
          author: 'Admin', // TODO: Remplacer par l'utilisateur connecté
          message: messageController.text.trim(),
          type: selectedType,
        ));
      });
      _save(popOnSuccess: false);
    }
  }

  Future<void> _save({bool popOnSuccess = true}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCiId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un CI impacté')));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final repository = Provider.of<StatusProvider>(context, listen: false).repository;
      
      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final event = StatusEvent(
        id: _currentEventId ?? const Uuid().v4(), 
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: _selectedStatus,
        affectedCiId: _selectedCiId!,
        startTime: _startTime,
        endTime: _endTime,
        stage: _selectedStage,
        tags: tags,
        externalLink: _externalLinkController.text.trim().isEmpty ? null : _externalLinkController.text.trim(),
        externalRef: _externalRefController.text.trim().isEmpty ? null : _externalRefController.text.trim(),
        posts: _posts,
      );

      if (_currentEventId == null) {
        await repository.createEvent(event);
        _currentEventId = event.id;
      } else {
        await repository.updateEvent(event);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (popOnSuccess) {
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Événement / Notes auvegardées', textAlign: TextAlign.center)));
        }
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
    if (_isLoadingDropdowns) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Nouvel Événement' : "Modifier l'Événement"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Titre de l'incident", border: OutlineInputBorder()),
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
              DropdownButtonFormField<String>(
                value: _selectedCiId,
                decoration: const InputDecoration(labelText: 'CI Impacté (Racine)', border: OutlineInputBorder()),
                items: _availableCIs.map((ci) => DropdownMenuItem(
                  value: ci.id,
                  child: Text(ci.name),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCiId = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CIStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Gravité (Statut Provoqué)', border: OutlineInputBorder()),
                      items: CIStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<IncidentStage>(
                      value: _selectedStage,
                      decoration: const InputDecoration(labelText: 'Étape (Cycle de vie)', border: OutlineInputBorder()),
                       items: IncidentStage.values.map((stage) => DropdownMenuItem(
                        value: stage,
                        child: Text(stage.name.toUpperCase()),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedStage = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDateTime(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date de Début', border: OutlineInputBorder()),
                        child: Text(dateFormat.format(_startTime)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDateTime(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date de Fin (Clôture)', border: OutlineInputBorder()),
                        child: Text(_endTime != null ? dateFormat.format(_endTime!) : 'En cours (Non défini)'),
                      ),
                    ),
                  ),
                  if (_endTime != null)
                     IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => setState(() => _endTime = null),
                     )
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags de Scope (séparés par des virgules)', 
                  border: OutlineInputBorder(),
                  hintText: 'LILLE, WEB, FRANCE'
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _externalRefController,
                      decoration: const InputDecoration(labelText: 'Référence Externe (ex: INC-1234)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _externalLinkController,
                      decoration: const InputDecoration(labelText: 'Lien Externe (Jira/ServiceNow)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notes de suivi (Posts)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_comment, color: Colors.indigo),
                    onPressed: _addPost,
                    tooltip: 'Ajouter une note',
                  )
                ],
              ),
              const Divider(),
              if (_posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Aucune note pour cet événement.'),
                )
              else
                ..._posts.map((post) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(post.message),
                    subtitle: Text('${dateFormat.format(post.date)} - ${post.author} (${post.type.name})'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        setState(() => _posts.remove(post));
                        _save(popOnSuccess: false);
                      },
                    ),
                  ),
                )),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Enregistrer l'événement"),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
