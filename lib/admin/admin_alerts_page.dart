import 'package:flutter/material.dart';
import 'package:mob_ass/map/map_layer.dart';
import 'package:mob_ass/models/safety_alert.dart';
import 'package:mob_ass/alerts/safety_alerts_store.dart';

class AdminAlertsPage extends StatefulWidget {
  const AdminAlertsPage({super.key});

  @override
  State<AdminAlertsPage> createState() => _AdminAlertsPageState();
}

class _AdminAlertsPageState extends State<AdminAlertsPage> {
  final SafetyAlertsStore _store = SafetyAlertsStore.instance;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _store.loadAlerts();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  MapLayerOption _optionFor(String typeId) => mapLayerOptions.firstWhere(
        (o) => o.id == typeId,
    orElse: () => mapLayerOptions.first,
  );

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

  Future<void> _openEditSheet(SafetyAlert alert) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditAlertSheet(alert: alert, store: _store),
    );
  }

  Future<void> _confirmDelete(SafetyAlert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete alert?'),
        content: Text('This will permanently remove "${alert.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _store.deleteAlert(alert.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _store.loadAlerts();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _store.alerts;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Manage Safety Alerts'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: alerts.isEmpty
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No alerts in the system yet.')),
              ),
            ],
          )
              : ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final option = _optionFor(alert.typeId);
              final severityColor = _severityColor(alert.severity);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                      left: BorderSide(color: severityColor, width: 4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(option.icon, color: option.color, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alert.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            '${option.label} • ${alert.status}'
                                '${alert.userReported ? ' • by traveler' : ' • official'}',
                            style:
                            const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          if (alert.description != null) ...[
                            const SizedBox(height: 4),
                            Text(alert.description!,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 20, color: Colors.blueGrey),
                          onPressed: () => _openEditSheet(alert),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          onPressed: () => _confirmDelete(alert),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


class _EditAlertSheet extends StatefulWidget {
  final SafetyAlert alert;
  final SafetyAlertsStore store;

  const _EditAlertSheet({required this.alert, required this.store});

  @override
  State<_EditAlertSheet> createState() => _EditAlertSheetState();
}

class _EditAlertSheetState extends State<_EditAlertSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _selectedType;
  late AlertSeverity _selectedSeverity;
  late String _selectedStatus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.alert.title);
    _descController = TextEditingController(text: widget.alert.description ?? '');
    _selectedType = widget.alert.typeId;
    _selectedSeverity = widget.alert.severity;
    _selectedStatus = widget.alert.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

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

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _saving = true);

    try {
      await widget.store.updateAlert(
        widget.alert.id,
        typeId: _selectedType,
        title: _titleController.text.trim(),
        description:
        _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        severity: _selectedSeverity,
        status: _selectedStatus,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Alert',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              const Text('Alert Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: mapLayerOptions.map((option) {
                  final selected = _selectedType == option.id;
                  return ChoiceChip(
                    label: Text(option.label),
                    avatar: Icon(option.icon,
                        size: 16, color: selected ? Colors.white : option.color),
                    selected: selected,
                    selectedColor: option.color,
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87, fontSize: 11),
                    onSelected: (_) => setState(() => _selectedType = option.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Text('Severity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AlertSeverity.values.map((severity) {
                  final selected = _selectedSeverity == severity;
                  final color = _severityColor(severity);
                  return ChoiceChip(
                    label: Text(_severityLabel(severity)),
                    selected: selected,
                    selectedColor: color,
                    backgroundColor: color.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    onSelected: (_) => setState(() => _selectedSeverity = severity),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Text('Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['active', 'resolved'].map((status) {
                  final selected = _selectedStatus == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: selected,
                    selectedColor: Colors.blueGrey,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.blueGrey,
                      fontSize: 11,
                    ),
                    onSelected: (_) => setState(() => _selectedStatus = status),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Text('Title',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}