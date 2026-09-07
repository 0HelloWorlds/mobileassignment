import 'package:flutter/material.dart';

class RoadStat {
  final String label;
  final int accidents;
  final int deaths;
  final double accidentSharePct;
  final double deathSharePct;

  const RoadStat({
    required this.label,
    required this.accidents,
    required this.deaths,
    required this.accidentSharePct,
    required this.deathSharePct,
  });
}

const List<RoadStat> _roadStats = [
  RoadStat(
    label: 'Municipal Road',
    accidents: 995377,
    deaths: 4587,
    accidentSharePct: 45.8,
    deathSharePct: 17.4,
  ),
  RoadStat(
    label: 'State Road',
    accidents: 404092,
    deaths: 7161,
    accidentSharePct: 18.6,
    deathSharePct: 27.2,
  ),
  RoadStat(
    label: 'Federal Road',
    accidents: 375825,
    deaths: 8539,
    accidentSharePct: 17.3,
    deathSharePct: 32.4,
  ),
  RoadStat(
    label: 'Expressway',
    accidents: 238863,
    deaths: 3335,
    accidentSharePct: 11.0,
    deathSharePct: 12.7,
  ),
  RoadStat(
    label: 'Other Roads',
    accidents: 157298,
    deaths: 2721,
    accidentSharePct: 7.2,
    deathSharePct: 10.3,
  ),
];

const Color _accidentColor = Color(0xFF2A78D6);
const Color _deathColor = Color(0xFFEB6834);

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final maxAccidents =
    _roadStats.map((r) => r.accidents).reduce((a, b) => a > b ? a : b);
    final maxDeaths =
    _roadStats.map((r) => r.deaths).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Road Safety Insights'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sourceNote(),
            const SizedBox(height: 16),
            _headlineCard(),
            const SizedBox(height: 20),
            _sectionTitle('Accident share vs. death share by road type'),
            const SizedBox(height: 8),
            _groupedBarChart(),
            const SizedBox(height: 20),
            _sectionTitle('Accidents by Road Type (2016-2019)'),
            const SizedBox(height: 8),
            _barChartCard(
              maxValue: maxAccidents,
              valueOf: (r) => r.accidents,
              barColor: Colors.blueGrey,
            ),
            const SizedBox(height: 20),
            _sectionTitle('Deaths by Road Type (2016-2019)'),
            const SizedBox(height: 8),
            _barChartCard(
              maxValue: maxDeaths,
              valueOf: (r) => r.deaths,
              barColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Source: Malaysian Government Open Data (data.gov.my), '
                  '2016-2019 national road accident statistics',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headlineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequency vs. Severity',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'Municipal roads see the most accidents overall (46% of all '
                'cases), but Federal roads have the highest death toll — '
                'proof that "how often" and "how deadly" are two different '
                'questions. This is exactly why Safe Route Planner scores '
                'routes on safety, not just distance or speed.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    );
  }

  Widget _groupedBarChart() {
    const barMaxHeight = 130.0;
    const chartHeight = barMaxHeight + 26;
    const maxPercent = 50.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              _LegendDot(color: _accidentColor, label: 'Share of accidents'),
              SizedBox(width: 16),
              _LegendDot(color: _deathColor, label: 'Share of deaths'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _roadStats.map((stat) {
                final accidentHeight =
                    (stat.accidentSharePct / maxPercent) * barMaxHeight;
                final deathHeight =
                    (stat.deathSharePct / maxPercent) * barMaxHeight;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBar(accidentHeight, _accidentColor,
                            '${stat.accidentSharePct.toStringAsFixed(0)}%'),
                        const SizedBox(width: 3),
                        _buildBar(deathHeight, _deathColor,
                            '${stat.deathSharePct.toStringAsFixed(0)}%'),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _roadStats.map((stat) {
              return SizedBox(
                width: 62,
                child: Text(
                  stat.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBar(double height, Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 16,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ),
      ],
    );
  }

  Widget _barChartCard({
    required int maxValue,
    required int Function(RoadStat) valueOf,
    required Color barColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: _roadStats.map((stat) {
          final value = valueOf(stat);
          final fraction = maxValue == 0 ? 0.0 : value / maxValue;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stat.label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(
                      _formatNumber(value),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 10,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          height: 10,
                          width: constraints.maxWidth * fraction,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000) {
      final thousands = value / 1000;
      return '${thousands.toStringAsFixed(thousands >= 100 ? 0 : 1)}k';
    }
    return value.toString();
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}