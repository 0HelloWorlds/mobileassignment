import 'package:flutter/material.dart';
import 'package:mob_ass/auth/auth_service.dart';
import 'package:mob_ass/models/app_user.dart';
import 'package:mob_ass/admin/admin_user_detail_page.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<AppUser> _allUsers = [];
  List<AppUser> _filteredUsers = [];
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
      final response = await supabase.functions.invoke('admin-get-users', body: {'role': 'user'});
      final users = (response.data['users'] as List).map((e) => AppUser.fromJson(e)).toList();
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredUsers = query.isEmpty
          ? _allUsers
          : _allUsers
              .where((u) =>
                  u.name.toLowerCase().contains(query) ||
                  u.email.toLowerCase().contains(query))
              .toList();
    });
  }

  Future<void> _toggleStatus(AppUser user) async {
    final newStatus = user.isActive ? 'inactive' : 'active';
    try {
      await supabase.functions.invoke('admin-update-user', body: {
        'target_user_id': user.id,
        'status': newStatus,
      });
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
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
        title: const Text('Registered Users'),
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
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? const Center(child: Text('No users found.'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredUsers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        user.isActive ? Colors.green : Colors.grey,
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(user.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(user.email),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        user.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: user.isActive ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                      Switch(
                                        value: user.isActive,
                                        onChanged: (_) => _toggleStatus(user),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final changed = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminUserDetailPage(user: user),
                                      ),
                                    );
                                    if (changed == true) _load();
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
