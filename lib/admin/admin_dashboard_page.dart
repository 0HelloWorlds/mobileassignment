import 'package:flutter/material.dart';
import 'package:mob_ass/auth/auth_service.dart';
import 'package:mob_ass/models/app_user.dart';
import 'package:mob_ass/admin/admin_users_page.dart';
import 'package:mob_ass/admin/create_admin_page.dart';
import 'package:mob_ass/admin/admin_account_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final AppUser admin;

  const AdminDashboardPage({super.key, required this.admin});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _totalUsers = 0;
  int _activeUsers = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final data = await supabase
        .from('user')
        .select('status')
        .eq('role', 'user');
    if (!mounted) return;
    final rows = data as List;
    setState(() {
      _totalUsers = rows.length;
      _activeUsers = rows.where((r) => r['status'] == 'active').length;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await signOutUser();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Admin Dashboard')
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${widget.admin.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(widget.admin.role,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _statCard('Total Users', _loading ? '-' : '$_totalUsers', Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard('Active Users', _loading ? '-' : '$_activeUsers', Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (widget.admin.isAdminManager) ...[
                  _menuTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Create Admin Account',
                    subtitle: 'Register a new ADMIN account',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (
                            context) => const CreateAdminPage()),
                      );
                    },
                  ),
                  _menuTile(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Manage Admin Accounts',
                    subtitle: 'View and search admin accounts',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminAccountsPage()
                        ),
                      );
                    },
                  ),
                ],
                _menuTile(
                  icon: Icons.people_outline,
                  title: 'Manage User Accounts',
                  subtitle: 'View and search user accounts',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminUsersPage(),
                      ),
                    );
                    if (mounted) {
                      _loadStats();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
