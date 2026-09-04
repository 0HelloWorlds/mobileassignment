import 'package:flutter/material.dart';

class MapLayerOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  const MapLayerOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const List<MapLayerOption> mapLayerOptions = [
  MapLayerOption(
    id: 'accident',
    label: 'Accident Hotspots',
    subtitle: 'Show accident locations',
    icon: Icons.warning_amber_rounded,
    color: Colors.red,
  ),
  MapLayerOption(
    id: 'flood',
    label: 'Flood Areas',
    subtitle: 'Show flood-prone areas',
    icon: Icons.waves,
    color: Colors.blue,
  ),
  MapLayerOption(
    id: 'weather',
    label: 'Weather',
    subtitle: 'Show weather radar',
    icon: Icons.cloud_outlined,
    color: Colors.lightBlue,
  ),
  MapLayerOption(
    id: 'road_closed',
    label: 'Road Closure',
    subtitle: 'Show closed roads',
    icon: Icons.block,
    color: Colors.orange,
  ),
  MapLayerOption(
    id: 'construction',
    label: 'Construction Zones',
    subtitle: 'Show construction areas',
    icon: Icons.construction,
    color: Colors.amber,
  ),
];

class MapLayersPage extends StatefulWidget {
  final Set<String> initialSelected;

  const MapLayersPage({super.key, required this.initialSelected});

  @override
  State<MapLayersPage> createState() => _MapLayersPageState();
}

class _MapLayersPageState extends State<MapLayersPage> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  void _toggle(String id, bool value) {
    setState(() {
      if (value) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Map Layers'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: mapLayerOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = mapLayerOptions[index];
                final isChecked = _selected.contains(option.id);
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    value: isChecked,
                    onChanged: (value) => _toggle(option.id, value ?? false),
                    controlAffinity: ListTileControlAffinity.trailing,
                    activeColor: Colors.green,
                    secondary: Icon(option.icon, color: option.color),
                    title: Text(
                      option.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      option.subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, _selected),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}