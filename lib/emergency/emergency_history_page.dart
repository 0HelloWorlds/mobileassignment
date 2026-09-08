import 'package:flutter/material.dart';
import 'package:mob_ass/map/history_location.dart';
import 'package:mob_ass/auth/auth_service.dart';
import 'package:mob_ass/models/emergency_request.dart';

const Map<String, IconData> _typeIcons = {
  'SOS': Icons.sos,
  'Vehicle Breakdown': Icons.car_repair,
};

const Map<String, Color> _typeColors = {
  'SOS': Colors.red,
  'Vehicle Breakdown': Colors.brown,
};

class EmergencyHistoryPage extends StatefulWidget {
  const EmergencyHistoryPage({super.key});

  @override
  State<EmergencyHistoryPage> createState() => _EmergencyHistoryPageState();
}

class _EmergencyHistoryPageState extends State<EmergencyHistoryPage> {
  List<EmergencyRequest> _requests = [];
  bool _loading = true;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<EmergencyRequest> get _filteredRequests {
    if (_filterType == null) return _requests;
    return _requests.where((r) => r.emergencyType == _filterType).toList();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await supabase.functions.invoke('get-emergency-requests');
      final requests = (response.data['requests'] as List)
          .map((e) => EmergencyRequest.fromJson(e))
          .toList();
      if (!mounted) return;
      setState(() => _requests = requests);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load history: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteRequest(EmergencyRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Remove this emergency record from your history?'),
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
      final response = await supabase.functions.invoke('delete-emergency-request', body: {
        'request_id': request.requestId,
      });
      if (response.data['success'] == true) {
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete record: $e')));
    }
  }

  IconData _iconFor(String type) => _typeIcons[type] ?? Icons.sos;

  Color _colorFor(String type) => _typeColors[type] ?? Colors.red;

  void _showDetails(EmergencyRequest request) {
    final color = _colorFor(request.emergencyType);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(request.emergencyType), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.emergencyType,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(_formatFullDate(request.createdAt),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Text('Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              request.address ?? 'Location not recorded',
              style: const TextStyle(fontSize: 14),
            ),
            if (request.latitude != 0 && request.longitude != 0) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openInMaps(request),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Open in Maps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteRequest(request);
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Record'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openInMaps(EmergencyRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyLocationMapPage(
          latitude: request.latitude,
          longitude: request.longitude,
          address: request.address,
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} · '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatListDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    final time = '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    if (diff == 0) return 'Today · $time';
    if (diff == 1) return 'Yesterday · $time';
    return _formatFullDate(date);
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _filterType == null,
              onSelected: (_) => setState(() => _filterType = null),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('SOS'),
              selected: _filterType == 'SOS',
              onSelected: (_) => setState(() => _filterType = 'SOS'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Vehicle Breakdown'),
              selected: _filterType == 'Vehicle Breakdown',
              onSelected: (_) => setState(() => _filterType = 'Vehicle Breakdown'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRequests;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Emergency History'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final request = filtered[index];
                    final color = _colorFor(request.emergencyType);
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showDetails(request),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_iconFor(request.emergencyType),
                                    color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(request.emergencyType,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 3),
                                    Text(_formatListDate(request.createdAt),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                    if (request.address != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        request.address!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.black54, fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.red),
                                onPressed: () => _deleteRequest(request),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Icon(Icons.history, size: 56, color: Colors.grey[350]),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _filterType == null
                  ? 'No past emergency requests'
                  : 'No $_filterType records',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'SOS calls you make will show up here.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}