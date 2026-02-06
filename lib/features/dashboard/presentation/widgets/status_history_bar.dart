import 'package:flutter/material.dart';
import '../../../admin/domain/entities/daily_status.dart';
import '../../../admin/domain/entities/ci.dart';

class StatusHistoryBar extends StatelessWidget {
  final List<DailyStatus> history;

  const StatusHistoryBar({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Row(
      children: history.map((daily) {
        return Expanded(
          child: Tooltip(
            message: '${_formatDate(daily.date)}: ${_getStatusLabel(daily.status)}',
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              height: 20,
              decoration: BoxDecoration(
                color: _getColorForStatus(daily.status),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _getStatusLabel(CIStatus status) {
     switch (status) {
      case CIStatus.operational: return 'Opérationnel';
      case CIStatus.degraded: return 'Dégradé';
      case CIStatus.down: return 'Panne';
      case CIStatus.maintenance: return 'Maintenance';
    }
  }

  Color _getColorForStatus(CIStatus status) {
    switch (status) {
      case CIStatus.operational: return Colors.green.shade400;
      case CIStatus.degraded: return Colors.orange;
      case CIStatus.down: return Colors.red;
      case CIStatus.maintenance: return Colors.grey.withOpacity(0.3); // Maintenance ignorée ou discrète
    }
  }
}
