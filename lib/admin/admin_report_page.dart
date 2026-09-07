import 'package:flutter/material.dart';
import 'package:mob_ass/auth/auth_service.dart';

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  bool _loading = true;

  // User statistics
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _inactiveUsers = 0;

  // Safety alert statistics
  int _totalAlerts = 0;
  int _highAlerts = 0;
  int _mediumAlerts = 0;
  int _lowAlerts = 0;
  int _activeAlerts = 0;
  int _resolvedAlerts = 0;

  // Emergency statistics
  int _totalEmergencyRequests = 0;
  int _sosRequests = 0;
  int _vehicleBreakdownRequests = 0;

  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
    });

    try {
      // =========================
      // USER REPORT
      // =========================

      final userData = await supabase
          .from('user')
          .select('status')
          .eq('role', 'user');

      final users = userData as List;

      _totalUsers = users.length;

      _activeUsers = users
          .where((user) => user['status'] == 'active')
          .length;

      _inactiveUsers = users
          .where((user) => user['status'] != 'active')
          .length;


      // =========================
      // SAFETY ALERT REPORT
      // =========================

      dynamic alertQuery = supabase
          .from('safetyalerts')
          .select('severity, status');

      final alertData = await alertQuery;

      final alerts = alertData as List;

      _totalAlerts = alerts.length;

      _highAlerts = alerts
          .where((alert) => alert['severity'] == 'high')
          .length;

      _mediumAlerts = alerts
          .where((alert) => alert['severity'] == 'medium')
          .length;

      _lowAlerts = alerts
          .where((alert) => alert['severity'] == 'low')
          .length;

      _activeAlerts = alerts
          .where((alert) => alert['status'] == 'active')
          .length;

      _resolvedAlerts = alerts
          .where((alert) => alert['status'] == 'resolved')
          .length;


      // =========================
      // EMERGENCY REPORT
      // =========================

      final emergencyData = await supabase
          .from('emergency_requests')
          .select('emergency_type');

      final emergencies = emergencyData as List;

      _totalEmergencyRequests = emergencies.length;

      _sosRequests = emergencies
          .where((emergency) => emergency['emergency_type'] == 'SOS')
          .length;

      _vehicleBreakdownRequests = emergencies
          .where(
              (emergency) =>
          emergency['emergency_type'] == 'Vehicle Breakdown')
          .length;

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // =========================
  // DATE RANGE PICKER
  // =========================

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked =
    await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });

      _loadReportByDate();
    }
  }


  // =========================
  // LOAD REPORT BY DATE
  // =========================

  Future<void> _loadReportByDate() async {
    if (_selectedDateRange == null) {
      _loadReport();
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final startDate =
      _selectedDateRange!.start.toIso8601String();

      final endDate =
      _selectedDateRange!.end
          .add(const Duration(days: 1))
          .toIso8601String();


      // =========================
      // SAFETY ALERTS BY DATE
      // =========================

      final alertData = await supabase
          .from('safetyalerts')
          .select('severity, status')
          .gte('created_at', startDate)
          .lt('created_at', endDate);

      final alerts = alertData as List;

      _totalAlerts = alerts.length;

      _highAlerts =
          alerts.where((alert) => alert['severity'] == 'high').length;

      _mediumAlerts =
          alerts.where((alert) => alert['severity'] == 'medium').length;

      _lowAlerts =
          alerts.where((alert) => alert['severity'] == 'low').length;

      _activeAlerts =
          alerts.where((alert) => alert['status'] == 'active').length;

      _resolvedAlerts =
          alerts.where((alert) => alert['status'] == 'resolved').length;


      // =========================
      // EMERGENCY REQUESTS BY DATE
      // =========================

      final emergencyData = await supabase
          .from('emergency_requests')
          .select('emergency_type')
          .gte('created_at', startDate)
          .lt('created_at', endDate);

      final emergencies = emergencyData as List;

      _totalEmergencyRequests = emergencies.length;

      _sosRequests = emergencies
          .where((emergency) => emergency['emergency_type'] == 'SOS')
          .length;

      _vehicleBreakdownRequests = emergencies
          .where(
              (emergency) =>
          emergency['emergency_type'] == 'Vehicle Breakdown')
          .length;


      if (!mounted) return;

      setState(() {
        _loading = false;
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to filter report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // =========================
  // CLEAR DATE FILTER
  // =========================

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
    });

    _loadReport();
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'System Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _selectedDateRange == null
                ? _loadReport
                : _loadReportByDate,
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _selectedDateRange == null
              ? _loadReport
              : _loadReportByDate,

          child: _loading
              ? const Center(
            child: CircularProgressIndicator(),
          )

              : SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),

            padding:
            const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                // =========================
                // DATE FILTER
                // =========================

                _buildDateFilter(),

                const SizedBox(height: 20),


                // =========================
                // OVERVIEW
                // =========================

                const Text(
                  'System Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [

                    Expanded(
                      child: _statCard(
                        title: 'Users',
                        value: _totalUsers.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _statCard(
                        title: 'Safety Alerts',
                        value: _totalAlerts.toString(),
                        icon: Icons.warning_amber,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _statCard(
                  title: 'Emergency Requests',
                  value:
                  _totalEmergencyRequests.toString(),
                  icon: Icons.emergency,
                  color: Colors.red,
                ),

                const SizedBox(height: 25),


                // =========================
                // USER REPORT
                // =========================

                _sectionTitle(
                  'User Report',
                  Icons.people_outline,
                ),

                const SizedBox(height: 10),

                _reportCard(
                  children: [

                    _reportRow(
                      'Total Users',
                      _totalUsers,
                      Colors.blue,
                    ),

                    const Divider(),

                    _reportRow(
                      'Active Users',
                      _activeUsers,
                      Colors.green,
                    ),

                    const Divider(),

                    _reportRow(
                      'Inactive Users',
                      _inactiveUsers,
                      Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 25),


                // =========================
                // SAFETY ALERT REPORT
                // =========================

                _sectionTitle(
                  'Safety Alert Report',
                  Icons.warning_amber_outlined,
                ),

                const SizedBox(height: 10),

                _reportCard(
                  children: [

                    _reportRow(
                      'Total Alerts',
                      _totalAlerts,
                      Colors.orange,
                    ),

                    const Divider(),

                    _reportRow(
                      'High Severity',
                      _highAlerts,
                      Colors.red,
                    ),

                    const Divider(),

                    _reportRow(
                      'Medium Severity',
                      _mediumAlerts,
                      Colors.orange,
                    ),

                    const Divider(),

                    _reportRow(
                      'Low Severity',
                      _lowAlerts,
                      Colors.green,
                    ),

                    const Divider(),

                    _reportRow(
                      'Active Alerts',
                      _activeAlerts,
                      Colors.blue,
                    ),

                    const Divider(),

                    _reportRow(
                      'Resolved Alerts',
                      _resolvedAlerts,
                      Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 25),


                // =========================
                // EMERGENCY REPORT
                // =========================

                _sectionTitle(
                  'Emergency Assistance Report',
                  Icons.emergency_outlined,
                ),

                const SizedBox(height: 10),

                _reportCard(
                  children: [

                    _reportRow(
                      'Total Requests',
                      _totalEmergencyRequests,
                      Colors.red,
                    ),

                    const Divider(),

                    _reportRow(
                      'SOS Requests',
                      _sosRequests,
                      Colors.redAccent,
                    ),

                    const Divider(),

                    _reportRow(
                      'Vehicle Breakdown',
                      _vehicleBreakdownRequests,
                      Colors.brown,
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // =========================
  // DATE FILTER WIDGET
  // =========================

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          const Text(
            'Report Period',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 10),

          if (_selectedDateRange == null)

            const Text(
              'Showing all available records',
              style: TextStyle(
                color: Colors.grey,
              ),
            )

          else

            Text(
              '${_formatDate(_selectedDateRange!.start)} - '
                  '${_formatDate(_selectedDateRange!.end)}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),

          const SizedBox(height: 12),

          Row(
            children: [

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,

                  icon:
                  const Icon(Icons.date_range),

                  label:
                  const Text('Select Date'),

                  style:
                  OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              if (_selectedDateRange != null) ...[

                const SizedBox(width: 10),

                IconButton(
                  onPressed: _clearDateFilter,

                  icon:
                  const Icon(Icons.clear),

                  tooltip:
                  'Clear Filter',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }


  // =========================
  // STAT CARD
  // =========================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color: color,
            size: 28,
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight:
              FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }


  // =========================
  // SECTION TITLE
  // =========================

  Widget _sectionTitle(
      String title,
      IconData icon,
      ) {
    return Row(
      children: [

        Icon(
          icon,
          color: Colors.green,
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ],
    );
  }


  // =========================
  // REPORT CARD
  // =========================

  Widget _reportCard({
    required List<Widget> children,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(12),
      ),

      child: Column(
        children: children,
      ),
    );
  }


  // =========================
  // REPORT ROW
  // =========================

  Widget _reportRow(
      String label,
      int value,
      Color color,
      ) {
    return Row(
      children: [

        Container(
          width: 10,
          height: 10,

          decoration: BoxDecoration(
            color: color,
            shape:
            BoxShape.circle,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ),

        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}