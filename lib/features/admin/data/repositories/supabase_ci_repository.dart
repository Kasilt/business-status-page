import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/ci.dart';
import '../../domain/entities/dependency.dart';
import '../../domain/entities/status_event.dart';
import '../../domain/entities/daily_status.dart';
import '../../domain/repositories/ci_repository.dart';
import '../../domain/entities/journey_map.dart';

class SupabaseCIRepository implements CIRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<CI>> getAllCIs() async {
    final response = await _client.from('cis').select();
    
    // Pour l'historique, on génère du mock pour l'instant ou on le calcule
    // Dans cette version 1, on va laisser l'historique vide ou mocké le temps de faire la requête complexe
    return (response as List).map((json) {
      return CI(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        type: _parseType(json['type']),
        scope: _parseScope(json['scope']),
        status: CIStatus.operational, // Statut par défaut, sera écrasé par le calcul
        tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
        history: [], // TODO: Implémenter l'historique réel
      );
    }).toList();
  }

  @override
  Future<List<Dependency>> getAllDependencies() async {
    final response = await _client.from('dependencies').select();
    return (response as List).map((json) => Dependency(
      id: json['id'].toString(),
      sourceCiId: json['source_ci_id'],
      targetCiId: json['target_ci_id'],
      impactWeight: json['impact_weight'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    )).toList();
  }

  @override
  Future<List<StatusEvent>> getAllEvents() async {
    // On récupère les événements avec leurs posts
    final response = await _client.from('events').select('*, event_posts(*)');
    
    return (response as List).map((json) {
      final posts = (json['event_posts'] as List).map((p) => EventPost(
        id: p['id'],
        date: DateTime.parse(p['posted_at']).toLocal(),
        author: p['author'],
        message: p['message'],
        type: _parsePostType(p['type']),
      )).toList();

      // Trier les posts par date
      posts.sort((a, b) => b.date.compareTo(a.date));

      return StatusEvent(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        status: _parseStatus(json['status']),
        affectedCiId: json['affected_ci_id'],
        startTime: DateTime.parse(json['start_time']).toLocal(),
        endTime: json['end_time'] != null ? DateTime.parse(json['end_time']).toLocal() : null,
        posts: posts,
        stage: _parseStage(json['stage']),
        tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
        externalLink: json['external_link'],
        externalRef: json['external_ref'],
      );
    }).toList();
  }

  // --- Parsers ---
  
  CIType _parseType(String type) {
    switch (type) {
      case 'application': return CIType.application;
      case 'technical': return CIType.technical;
      case 'businessService': return CIType.businessService; // Attention à la casse dans DB
      default: return CIType.application;
    }
  }

  CIScope _parseScope(String scope) {
    return scope == 'local' ? CIScope.local : CIScope.global;
  }

  CIStatus _parseStatus(String status) {
    switch (status) {
      case 'operational': return CIStatus.operational;
      case 'degraded': return CIStatus.degraded;
      case 'down': return CIStatus.down;
      case 'maintenance': return CIStatus.maintenance;
      default: return CIStatus.operational;
    }
  }

  IncidentStage _parseStage(String? stage) {
    switch (stage) {
      case 'detection': return IncidentStage.detection;
      case 'investigation': return IncidentStage.investigation;
      case 'identified': return IncidentStage.identified;
      case 'monitoring': return IncidentStage.monitoring;
      case 'resolved': return IncidentStage.resolved;
      case 'closed': return IncidentStage.closed;
      default: return IncidentStage.detection;
    }
  }

  EventPostType _parsePostType(String type) {
    switch (type) {
      case 'detection': return EventPostType.detection;
      case 'investigation': return EventPostType.investigation;
      case 'identified': return EventPostType.identified;
      case 'monitoring': return EventPostType.monitoring;
      case 'resolved': return EventPostType.resolved;
      case 'workaround': return EventPostType.workaround;
      default: return EventPostType.detection;
    }
  }

  // --- Event Write Operations ---

  @override
  Future<void> createEvent(StatusEvent event) async {
    // 1. Insert the main event
    await _client.from('events').insert({
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'status': event.status.name, // Will be mapped back in the DB triggers/logic if necessary, or just store String
      'affected_ci_id': event.affectedCiId,
      'start_time': event.startTime.toIso8601String(),
      'end_time': event.endTime?.toIso8601String(),
      'stage': event.stage.name,
      'tags': event.tags,
      'external_link': event.externalLink,
      'external_ref': event.externalRef,
    });

    // 2. Insert posts if any
    if (event.posts.isNotEmpty) {
      final postsParam = event.posts.map((p) => {
        'id': p.id,
        'event_id': event.id,
        'posted_at': p.date.toIso8601String(),
        'author': p.author,
        'message': p.message,
        'type': p.type.name,
      }).toList();

      await _client.from('event_posts').insert(postsParam);
    }
  }

  @override
  Future<void> updateEvent(StatusEvent event) async {
    // 1. Update the main event
    await _client.from('events').update({
      'title': event.title,
      'description': event.description,
      'status': event.status.name,
      'affected_ci_id': event.affectedCiId,
      'start_time': event.startTime.toIso8601String(),
      'end_time': event.endTime?.toIso8601String(),
      'stage': event.stage.name,
      'tags': event.tags,
      'external_link': event.externalLink,
      'external_ref': event.externalRef,
    }).eq('id', event.id);

    // 2. For simplicity, delete all old posts and recreate them (or diff if performance is an issue)
    await _client.from('event_posts').delete().eq('event_id', event.id);

    if (event.posts.isNotEmpty) {
      final postsParam = event.posts.map((p) => {
        'id': p.id,
        'event_id': event.id,
        'posted_at': p.date.toIso8601String(),
        'author': p.author,
        'message': p.message,
        'type': p.type.name,
      }).toList();

      await _client.from('event_posts').insert(postsParam);
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    // Assuming ON DELETE CASCADE is set up in the DB for event_posts.
    // If not, we should delete event_posts manually here first.
    // For safety, let's delete posts explicitly if cascade is missing just in case:
    await _client.from('event_posts').delete().eq('event_id', id);
    await _client.from('events').delete().eq('id', id);
  }

  @override
  Future<void> createCI(CI ci) async {
    await _client.from('cis').insert({
      'id': ci.id,
      'name': ci.name,
      'description': ci.description,
      'type': ci.type.name, // 'application', 'technical', etc.
      'scope': ci.scope.name, // 'global', 'local'
      'tags': ci.tags,
      // 'status' est calculé, pas stocké directement comme propriété statique généralement, 
      // mais ici on peut initialiser si besoin ou ignorer.
    });
  }

  @override
  Future<void> updateCI(CI ci) async {
    final response = await _client.from('cis').update({
      'name': ci.name,
      'description': ci.description,
      'type': ci.type.name,
      'scope': ci.scope.name,
      'tags': ci.tags,
    }).eq('id', ci.id).select();
    
    if (response.isEmpty) {
      throw Exception('Aucun CI classé pour une mise à jour. Vérifiez les droits ou l\'ID.');
    }
  }

  @override
  Future<void> deleteCI(String id) async {
    // Vérification des dépendances
    final deps = await _client.from('dependencies').select('id').or('source_ci_id.eq.$id,target_ci_id.eq.$id');
    if (deps.isNotEmpty) {
      throw Exception('Impossible de supprimer ce CI : il est utilisé dans une ou plusieurs dépendances.');
    }

    // Vérification des journey maps
    final jmCis = await _client.from('journey_map_cis').select('ci_id').eq('ci_id', id);
    if (jmCis.isNotEmpty) {
      throw Exception('Impossible de supprimer ce CI : il est utilisé dans une Journey Map.');
    }

    // Vérification de l'historique (événements)
    final events = await _client.from('events').select('id').eq('affected_ci_id', id);
    if (events.isNotEmpty) {
      throw Exception('Impossible de supprimer ce CI : il a des événements d\'historique associés.');
    }

    final response = await _client.from('cis').delete().eq('id', id).select();
    
    if (response.isEmpty) {
        throw Exception('Aucun CI supprimé. Vérifiez les droits ou l\'ID.');
    }
  }

  // --- Dependency Write Operations ---
  
  @override
  Future<void> createDependency(Dependency dep) async {
    await _client.from('dependencies').insert({
      'source_ci_id': dep.sourceCiId,
      'target_ci_id': dep.targetCiId,
      'impact_weight': dep.impactWeight,
      'tags': dep.tags,
    });
  }

  @override
  Future<void> updateDependency(Dependency dep) async {
    await _client.from('dependencies').update({
      'source_ci_id': dep.sourceCiId, // Généralement on ne change pas les clés étrangères, mais bon
      'target_ci_id': dep.targetCiId,
      'impact_weight': dep.impactWeight,
      'tags': dep.tags,
    }).eq('id', int.parse(dep.id));
  }

  @override
  Future<void> deleteDependency(String id) async {
    final res = await _client.from('dependencies').delete().eq('id', int.parse(id)).select();
    if (res.isEmpty) {
      throw Exception('Aucune dépendance supprimée. Vérifiez les droits ou l\'ID.');
    }
  }

  // --- Journey Map Operations ---

  @override
  Future<List<JourneyMap>> getAllJourneyMaps() async {
    final response = await _client.from('journey_maps').select('*, journey_map_cis(*)');
    
    return (response as List).map((json) {
      return JourneyMap.fromJson(json);
    }).toList();
  }

  @override
  Future<void> createJourneyMap(JourneyMap jm) async {
    // 1. Create the Journey Map entry
    await _client.from('journey_maps').insert({
      'name': jm.name,
      'description': jm.description,
      'tags': jm.tags,
    });
    
    // 2. Insert the associated CIs if any
    if (jm.cis.isNotEmpty) {
      // In a real app we might need to fetch the generated ID if it wasn't provided,
      // but assuming the ID is generated centrally or we handle it in a transaction.
      // For simplicity here, if the ID is generated by DB, we would have requested it back.
      // Assuming 'jm' here has the correct UUID or we use a stored procedure for full creation.
    }
  }

  @override
  Future<void> updateJourneyMap(JourneyMap jm) async {
    // 1. Update Map metadata
    await _client.from('journey_maps').update({
      'name': jm.name,
      'description': jm.description,
      'tags': jm.tags,
    }).eq('id', jm.id);
    
    // 2. Clear old CIs and insert new ones (replace all strategy)
    // In production, calculating diffs is better for performance, but this is safer for now.
    await _client.from('journey_map_cis').delete().eq('journey_map_id', jm.id);
    
    if (jm.cis.isNotEmpty) {
      final cisParams = jm.cis.map((jmCi) => {
        'journey_map_id': jm.id,
        'ci_id': jmCi.ciId,
        'position': jmCi.position,
      }).toList();
      
      await _client.from('journey_map_cis').insert(cisParams);
    }
  }

  @override
  Future<void> deleteJourneyMap(String id) async {
    await _client.from('journey_maps').delete().eq('id', id);
  }
}
