import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:business_status_page/features/admin/domain/entities/status_event.dart';

/// Écran de Timeline d'un événement
class EventTimelineScreen extends StatelessWidget {
  final StatusEvent event;

  const EventTimelineScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'Incident'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de l'incident
            Text(
              event.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStageColor(event.stage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _getStageColor(event.stage)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStageIcon(event.stage), size: 16, color: _getStageColor(event.stage)),
                  const SizedBox(width: 8),
                  Text(
                    'Phase : ${_formatStage(event.stage)}',
                    style: TextStyle(color: _getStageColor(event.stage), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // BUs Impactées
            if (event.impactedBus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Wrap(
                  spacing: 8,
                  children: event.impactedBus.map((bu) => Chip(
                    label: Text(bu, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.grey.shade200,
                  )).toList(),
                ),
              ),

            // Lien Externe
            if (event.externalLink != null)
               Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () {
                    // TODO: Implement URL Launching
                    // launchUrl(Uri.parse(event.externalLink!));
                    print('Ouvrir ${event.externalLink}');
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        event.externalRef != null ? 'Voir ticket ${event.externalRef}' : 'Voir le ticket externe',
                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ),

             Text(
              event.description,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              event.description,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            
            // Timeline
            ...event.posts.map((post) => _buildTimelineItem(post, event.posts.last == post)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(EventPost post, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonne de gauche (Ligne + Rond)
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getColorForType(post.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIconForType(post.type), color: Colors.white, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Contenu du Post (Carte)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête (Auteur + Date)
                  Row(
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(post.date), // Nécessite intl, ou format simple
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bulle de message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(post.message),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(EventPostType type) {
    switch (type) {
      case EventPostType.detection: return Colors.red;
      case EventPostType.investigation: return Colors.orange;
      case EventPostType.identified: return Colors.deepOrange;
      case EventPostType.workaround: return Colors.purple;
      case EventPostType.monitoring: return Colors.blueGrey;
      case EventPostType.resolved: return Colors.green;
      case EventPostType.info: return Colors.blue;
    }
  }

  IconData _getIconForType(EventPostType type) {
    switch (type) {
      case EventPostType.detection: return Icons.warning_amber;
      case EventPostType.investigation: return Icons.search;
      case EventPostType.identified: return Icons.gps_fixed;
      case EventPostType.workaround: return Icons.build;
      case EventPostType.monitoring: return Icons.visibility;
      case EventPostType.resolved: return Icons.check_circle;
      case EventPostType.info: return Icons.info_outline;
    }
  }

  Color _getStageColor(IncidentStage stage) {
    switch (stage) {
      case IncidentStage.detection: return Colors.red;
      case IncidentStage.investigation: return Colors.orange;
      case IncidentStage.identified: return Colors.deepOrange;
      case IncidentStage.monitoring: return Colors.blue;
      case IncidentStage.resolved: return Colors.green;
      case IncidentStage.closed: return Colors.grey;
    }
  }

  IconData _getStageIcon(IncidentStage stage) {
    switch (stage) {
      case IncidentStage.detection: return Icons.warning_amber;
      case IncidentStage.investigation: return Icons.search;
      case IncidentStage.identified: return Icons.gps_fixed;
      case IncidentStage.monitoring: return Icons.visibility;
      case IncidentStage.resolved: return Icons.check_circle;
      case IncidentStage.closed: return Icons.archive;
    }
  }

  String _formatStage(IncidentStage stage) {
    switch (stage) {
      case IncidentStage.detection: return "Détection";
      case IncidentStage.investigation: return "Investigation";
      case IncidentStage.identified: return "Identifié";
      case IncidentStage.monitoring: return "Surveillance";
      case IncidentStage.resolved: return "Résolu";
      case IncidentStage.closed: return "Clôturé";
    }
  }
}
