import 'ci.dart';

enum EventPostType {
  detection, // Détection d'un incident
  investigation, // Investigation en cours
  identified, // Cause identifiée
  workaround, // Contournement
  monitoring, // Surveillance
  resolved, // Résolution
  info, // Information diverse
}

/// Un message dans le fil de l'événement
/// Analogie AS/400 : Une entrée dans le journal des incidents (Help Desk)
class EventPost {
  final String id;
  final DateTime date;
  final String author;
  final String message;
  final EventPostType type;

  EventPost({
    required this.id,
    required this.date,
    required this.author,
    required this.message,
    this.type = EventPostType.info,
  });
}

/// Phase de l'incident (Cycle de vie)
enum IncidentStage {
  detection, 
  investigation, 
  identified, 
  monitoring, 
  resolved, 
  closed 
}

/// Un Événement (Incident, Maintenance...)
class StatusEvent {
  final String id;
  final String title;
  final String description;
  final CIStatus status; // Le statut que cet événement provoque (ex: Panne)
  final String affectedCiId; // Le CI racine touché
  final DateTime startTime;
  final DateTime? endTime; // Null si en cours
  final List<EventPost> posts;
  
  // Nouveaux champs Phase 2
  final IncidentStage stage; 
  final List<String> impactedBus; // Codes des BUs impactées (ex: 'LILLE', 'WEB')
  final String? externalLink; // Lien Jira/ServiceNow
  final String? externalRef; // ID Externe (INC-1234)

  StatusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.affectedCiId,
    required this.startTime,
    this.endTime,
    this.posts = const [],
    this.stage = IncidentStage.detection,
    this.impactedBus = const [],
    this.externalLink,
    this.externalRef,
  });
}
