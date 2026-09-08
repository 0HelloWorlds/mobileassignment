import 'package:flutter/material.dart';
import 'package:mob_ass/map/map_layer.dart';
import 'package:mob_ass/models/safety_alert.dart';

class AlertDetailPage extends StatelessWidget {
  final SafetyAlert alert;

  const AlertDetailPage({super.key, required this.alert});

  Color _severityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.green;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.red;
    }
  }

  String _severityLabel(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
    }
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  MapLayerOption _optionFor(String typeId) => mapLayerOptions.firstWhere(
        (o) => o.id == typeId,
    orElse: () => mapLayerOptions.first,
  );

  @override
  Widget build(BuildContext context) {
    final option = _optionFor(alert.typeId);
    final severityColor = _severityColor(alert.severity);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Alert Details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: severityColor, width: 5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: option.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(option.icon, color: option.color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_severityLabel(alert.severity)} severity',
                            style: TextStyle(
                              color: severityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (alert.description != null) ...[
              _sectionLabel('Details'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(alert.description!, style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 16),
            ],

            _sectionLabel('Information'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.category_outlined, 'Type', option.label),
                  const Divider(height: 1),
                  _infoRow(Icons.access_time, 'Reported', _relativeTime(alert.reportedAt)),
                  const Divider(height: 1),
                  _infoRow(
                    Icons.person_outline,
                    'Source',
                    alert.userReported ? 'Reported by a traveler' : 'Official alert',
                  ),
                  const Divider(height: 1),
                  _infoRow(
                    Icons.location_on_outlined,
                    'Coordinates',
                    '${alert.position.latitude.toStringAsFixed(4)}, '
                        '${alert.position.longitude.toStringAsFixed(4)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}