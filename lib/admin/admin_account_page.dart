import 'package:flutter/material.dart';
import 'package:mob_ass/auth/auth_service.dart';
import 'package:mob_ass/models/app_user.dart';
import 'package:mob_ass/admin/admin_account_detail.dart';

class AdminAccountsPage extends StatefulWidget {
  const AdminAccountsPage({
    super.key,
  });

  @override
  State<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends State<AdminAccountsPage> {
  List<AppUser> _allAdmins = [];
  List<AppUser> _filteredAdmins = [];
  bool _loading = true;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _load();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final data = await supabase
          .from('user')
          .select()
          .eq('role', 'admin')
          .order('created_at', ascending: false);

      final admins =
      (data as List).map((e) => AppUser.fromJson(e)).toList();

      final query = _searchController.text.trim().toLowerCase();

      final filtered = query.isEmpty
          ? admins
          : admins
          .where(
            (admin) =>
        admin.name.toLowerCase().contains(query) ||
            admin.email.toLowerCase().contains(query),
      )
          .toList();

      if (!mounted) return;

      setState(() {
        _allAdmins = admins;
        _filteredAdmins = filtered;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load admins: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = query.isEmpty
        ? _allAdmins
        : _allAdmins
        .where(
          (admin) =>
      admin.name.toLowerCase().contains(query) ||
          admin.email.toLowerCase().contains(query),
    )
        .toList();

    setState(() {
      _filteredAdmins = filtered;
    });
  }

  Future<void> _toggleStatus(AppUser admin) async {
    final newStatus = admin.isActive ? 'inactive' : 'active';

    try {
      await supabase
          .from('user')
          .update({'status': newStatus})
          .eq('user_id', admin.id);

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update admin status: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Admin Accounts'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : _filteredAdmins.isEmpty
                  ? const Center(
                child: Text('No admin accounts found.'),
              )
                  : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: _filteredAdmins.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final admin = _filteredAdmins[index];

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: admin.isActive
                              ? Colors.green
                              : Colors.grey,
                          child: Text(
                            admin.name.isNotEmpty
                                ? admin.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        title: Text(
                          admin.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(admin.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              admin.isActive
                                  ? 'Active'
                                  : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                color: admin.isActive
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                            Switch(
                              value: admin.isActive,
                              onChanged: (_) => _toggleStatus(admin),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AdminAccountDetailPage(
                                    admin: admin,
                                  )
                            ),
                          );

                          if (changed == true) {
                            await _load();
                          }
                        },
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
}