import 'package:flutter/material.dart';
import 'package:mob_ass/map/map_layer.dart';
import 'package:mob_ass/models/safety_alert.dart';
import 'package:mob_ass/auth/auth_service.dart';
import 'package:mob_ass/alerts/safety_alerts_store.dart';

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


    final currentUserId = supabase.auth.currentUser?.id;
    final isOwner =
        currentUserId != null && alert.reportedBy == currentUserId;

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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: alert.status == 'resolved'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    alert.status == 'resolved'
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: alert.status == 'resolved'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    alert.status == 'resolved'
                        ? 'This alert has been resolved'
                        : 'This alert is still active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: alert.status == 'resolved'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),


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
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
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
                child: Text(alert.description!,
                    style: const TextStyle(fontSize: 14)),
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
                  _infoRow(Icons.access_time, 'Reported',
                      _relativeTime(alert.reportedAt)),
                  const Divider(height: 1),
                  _infoRow(
                    Icons.person_outline,
                    'Source',
                    alert.userReported
                        ? 'Reported by a traveler'
                        : 'Official alert',
                  ),
                  const Divider(height: 1),
                  _infoRow(
                    Icons.location_on_outlined,
                    'Coordinates',
                    '${alert.position.latitude.toStringAsFixed(4)}, '
                        '${alert.position.longitude.toStringAsFixed(4)}',
                  ),
                  const Divider(height: 1),
                  _infoRow(
                    Icons.check_circle_outline,
                    'Status',
                    alert.status == 'resolved' ? 'Resolved' : 'Active',
                  ),
                ],
              ),
            ),


            if (isOwner) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete My Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Report?'),
                        content: const Text(
                          'Are you sure you want to delete this report?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;

                    try {
                      await SafetyAlertsStore.instance.deleteAlert(alert.id);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete report: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
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
            style:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}