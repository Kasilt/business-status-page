import 'ci.dart';

/// Statut consolidé pour une journée
/// Analogie AS/400 : Une ligne dans le fichier statistique (HIST_STAT)
class DailyStatus {
  final DateTime date;
  final CIStatus status; // Le pire statut de la journée

  DailyStatus({
    required this.date,
    required this.status,
  });
}
