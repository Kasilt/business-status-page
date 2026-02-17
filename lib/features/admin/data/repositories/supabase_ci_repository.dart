import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/ci.dart';
import '../../domain/entities/dependency.dart';
import '../../domain/entities/status_event.dart';
import '../../domain/entities/daily_status.dart';
import '../../domain/repositories/ci_repository.dart';

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
      buFilter: json['bu_filter'] != null ? List<String>.from(json['bu_filter']) : null,
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
        impactedBus: json['impacted_bus'] != null ? List<String>.from(json['impacted_bus']) : [],
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

  @override
  Future<void> createCI(CI ci) async {
    await _client.from('cis').insert({
      'id': ci.id,
      'name': ci.name,
      'description': ci.description,
      'type': ci.type.name, // 'application', 'technical', etc.
      'scope': ci.scope.name, // 'global', 'local'
      // 'status' est calculé, pas stocké directement comme propriété statique généralement, 
      // mais ici on peut initialiser si besoin ou ignorer.
    });
  }

  @override
  Future<void> updateCI(CI ci) async {
    await _client.from('cis').update({
      'name': ci.name,
      'description': ci.description,
      'type': ci.type.name,
      'scope': ci.scope.name,
    }).eq('id', ci.id);
  }

  @override
  Future<void> deleteCI(String id) async {
    await _client.from('cis').delete().eq('id', id);
  }

  // --- Dependency Write Operations ---
  
  @override
  Future<void> createDependency(Dependency dep) async {
    await _client.from('dependencies').insert({
      'source_ci_id': dep.sourceCiId,
      'target_ci_id': dep.targetCiId,
      'impact_weight': dep.impactWeight,
      'bu_filter': dep.buFilter,
    });
  }

  @override
  Future<void> updateDependency(Dependency dep) async {
    await _client.from('dependencies').update({
      'source_ci_id': dep.sourceCiId, // Généralement on ne change pas les clés étrangères, mais bon
      'target_ci_id': dep.targetCiId,
      'impact_weight': dep.impactWeight,
      'bu_filter': dep.buFilter,
    }).eq('id', dep.id);
  }

  @override
  Future<void> deleteDependency(String id) async {
    await _client.from('dependencies').delete().eq('id', id);
  }
}
