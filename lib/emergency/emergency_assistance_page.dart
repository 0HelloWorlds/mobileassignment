import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:url_launcher/url_launcher.dart';
import 'package:mob_ass/auth/auth_service.dart';
import 'package:mob_ass/map/geocoding.dart';

class HotlineInfo {
  final String number;
  final String display;
  final String subtitle;
  const HotlineInfo(this.number, this.display, this.subtitle);
}

const HotlineInfo _defaultHotline = HotlineInfo('999', '999', 'Police · Fire · Ambulance');

const Map<String, HotlineInfo> _typeHotlines = {
  'Vehicle Breakdown':
  HotlineInfo('1800880000', '1-800-88-0000', 'PLUSLine · Highway Breakdown Assistance'),
};

const List<Map<String, dynamic>> _emergencyTypes = [
  {'label': 'SOS', 'icon': Icons.sos, 'color': Colors.red},
  {'label': 'Vehicle Breakdown', 'icon': Icons.car_repair, 'color': Colors.brown},
];

class EmergencyAssistancePage extends StatefulWidget {
  const EmergencyAssistancePage({super.key});

  @override
  State<EmergencyAssistancePage> createState() =>
      _EmergencyAssistancePageState();
}

class _EmergencyAssistancePageState extends State<EmergencyAssistancePage> {
  String? _selectedType;
  LatLng? _currentPosition;
  String? _currentAddress;
  bool _loadingLocation = false;

  bool _sending = false;

  HotlineInfo get _activeHotline => _typeHotlines[_selectedType] ?? _defaultHotline;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    final location = loc.Location();

    var serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }
    var permission = await location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await location.requestPermission();
    }

    if (!serviceEnabled ||
        (permission != loc.PermissionStatus.granted &&
            permission != loc.PermissionStatus.grantedLimited)) {
      if (!mounted) return;
      setState(() => _loadingLocation = false);
      return;
    }

    final data = await location.getLocation();
    if (data.latitude == null || data.longitude == null) {
      if (!mounted) return;
      setState(() => _loadingLocation = false);
      return;
    }

    final position = LatLng(data.latitude!, data.longitude!);
    final address = await reverseGeocode(position);
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
      _currentAddress = address ?? 'Location unavailable';
      _loadingLocation = false;
    });
  }

  void _selectType(String type) {
    setState(() => _selectedType = type);
  }

  Future<void> _callHotlineNumber() async {
    final uri = Uri(
      scheme: 'tel',
      path: _activeHotline.number,
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open phone dialer'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Call error: $e');
    }
  }

  Future<void> _logIncident() async {
    try {
      await supabase.functions.invoke('create-emergency-request', body: {
        'emergency_type': _selectedType ?? 'SOS',
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'address': _currentAddress,
      });
    } catch (e) {
      debugPrint('Failed to save emergency history: $e');
    }
  }

  Future<void> _confirmSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm SOS'),
        content: Text('This will call ${_activeHotline.display}. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);
    await _logIncident();
    await _callHotlineNumber();
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to your emergency history.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Emergency Assistance'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLocationCard(),
            const SizedBox(height: 20),
            const Text('What kind of emergency?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('This decides whether SOS calls 999 or PLUSLine.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            _buildTypeGrid(),
            const SizedBox(height: 20),
            _buildSosButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _currentPosition != null ? Icons.my_location : Icons.location_off,
            color: _currentPosition != null ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _loadingLocation
                ? const Text('Detecting your location…')
                : Text(
              _currentAddress ?? 'Location not available',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (_loadingLocation)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh location',
              onPressed: _getLocation,
            ),
        ],
      ),
    );
  }

  Widget _buildTypeGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: _emergencyTypes.map((type) {
        final selected = _selectedType == type['label'];
        return GestureDetector(
          onTap: () => _selectType(type['label'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: (type['color'] as Color).withOpacity(selected ? 0.25 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? (type['color'] as Color) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type['icon'] as IconData, color: type['color'] as Color, size: 28),
                const SizedBox(height: 6),
                Text(type['label'] as String,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: type['color'] as Color)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSosButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _sending ? null : _confirmSos,
        child: _sending
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sos, size: 26),
                const SizedBox(width: 10),
                Text('SOS · Call ${_activeHotline.display}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            const SizedBox(height: 2),
            Text(_activeHotline.subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}