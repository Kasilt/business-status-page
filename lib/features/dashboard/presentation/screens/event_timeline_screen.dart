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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                'Statut : En Cours (Depuis ${DateTime.now().difference(event.startTime).inHours}h)',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
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
      case EventPostType.workaround: return Colors.purple;
      case EventPostType.resolution: return Colors.green;
      case EventPostType.info: return Colors.blue;
    }
  }

  IconData _getIconForType(EventPostType type) {
    switch (type) {
      case EventPostType.detection: return Icons.warning_amber;
      case EventPostType.investigation: return Icons.search;
      case EventPostType.workaround: return Icons.build;
      case EventPostType.resolution: return Icons.check;
      case EventPostType.info: return Icons.info_outline;
    }
  }
}
