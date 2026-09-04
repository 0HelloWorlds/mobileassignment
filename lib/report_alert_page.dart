import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:mob_ass/map/map_layer.dart';
import 'package:mob_ass/safety_alerts_store.dart';

class ReportAlertPage extends StatefulWidget {
  const ReportAlertPage({super.key});

  @override
  State<ReportAlertPage> createState() => _ReportAlertPageState();
}

class _ReportAlertPageState extends State<ReportAlertPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final loc.Location _location = loc.Location();

  String _selectedType = mapLayerOptions.first.id;
  LatLng? _position;
  bool _locating = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
      }
      loc.PermissionStatus permission = await _location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await _location.requestPermission();
      }
      final hasPermission = permission == loc.PermissionStatus.granted ||
          permission == loc.PermissionStatus.grantedLimited;

      if (serviceEnabled && hasPermission) {
        final data = await _location.getLocation();
        if (data.latitude != null && data.longitude != null) {
          _position = LatLng(data.latitude!, data.longitude!);
        }
      }
    } catch (_) {
      // Leave _position null; the UI shows "location unavailable" + a retry button.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _position == null) return;
    setState(() => _submitting = true);

    SafetyAlertsStore.instance.reportAlert(
      typeId: _selectedType,
      title: _titleController.text.trim(),
      description:
      _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      position: _position!,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        !_submitting && _position != null && _titleController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Report Safety Alert'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Alert Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mapLayerOptions.map((option) {
                final selected = _selectedType == option.id;
                return ChoiceChip(
                  label: Text(option.label),
                  avatar: Icon(option.icon,
                      size: 18, color: selected ? Colors.white : option.color),
                  selected: selected,
                  selectedColor: option.color,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedType = option.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g. Accident near junction',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            const Text('Details (optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add more detail to help other travelers',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location,
                      color: _position != null ? Colors.green : Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _locating
                          ? 'Getting your current location...'
                          : _position != null
                          ? 'Using your current location'
                          : 'Location unavailable — enable GPS to report',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  if (!_locating && _position == null)
                    TextButton(
                      onPressed: _fetchCurrentLocation,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: canSubmit ? _submit : null,
                child: _submitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Submit Report',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}