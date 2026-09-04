import 'package:flutter/material.dart';
import 'package:mob_ass/auth/auth_service.dart';
import 'package:mob_ass/auth/login_page.dart';

import 'package:mob_ass/models/app_user.dart';
import 'package:mob_ass/models/emergency_contact.dart';

import 'package:mob_ass/profile/edit_profile_page.dart';
import 'package:mob_ass/profile/update_password_page.dart';

import 'package:mob_ass/profile/emergency_contact_form_page.dart';
import 'package:mob_ass/emergency/emergency_assistance_page.dart';
import 'package:mob_ass/emergency/emergency_history_page.dart';

import 'package:mob_ass/admin/admin_dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppUser? _profile;
  List<EmergencyContact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!isLoggedIn) {
      setState(() {
        _profile = null;
        _loading = false;
      });
      return;
    } else {
        setState(() => _loading = true);
        try {
          final profile = await fetchCurrentProfile();
          List<EmergencyContact> contacts = [];
          if (profile != null) {
            final data = await supabase
                .from('emergency_contacts')
                .select()
                .eq('user_id', profile.id)
                .order('created_at');
            contacts = (data as List)
                .map((e) => EmergencyContact.fromJson(e))
                .toList();
          }
          if (!mounted) {
            return;
          } else {
            setState(() {
              _profile = profile;
              _contacts = contacts;
            });
          }
        } catch (e) {
          if (!mounted) {
            return;
          } else {
            ScaffoldMessenger.of(context) .showSnackBar(
                SnackBar(content: Text('Failed to load profile: $e')));
          }
        } finally {
          if (mounted) {
            setState(() => _loading = false);
          }
        }
    }
  }

  Future<void> _goToLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
    if (result == true) {
      _load();
    }
  }

  Future<void> _logout() async {
    await signOutUser();
    if (!mounted) {
      return;
    } else {
      _load();
    }
  }

  void _goToAdminDashboard(AppUser profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDashboardPage(admin: profile),
      ),
    );
  }

  Future<void> _addContact() async {
    if (_contacts.length >= 3) {
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyContactFormPage(personalPhoneNumber: _profile!.phoneNumber)),
    );
    if (result == true) {
      await _load();
    }
  }

  Future<void> _editContact(EmergencyContact contact) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyContactFormPage(
          existing: contact,
          personalPhoneNumber: _profile!.phoneNumber,
        ),
      ),
    );
    if (result == true) {
      await _load();
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    if (_contacts.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must have at least 1 emergency contact.'),
        ),
      );
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: const Text('Delete Contact'),
              content: Text(
                  'Remove ${contact.fullName} from your emergency contacts?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                      'Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
      );
      if (confirmed != true) {
        return;
      } else {
        try {
          await supabase
              .from('emergency_contacts')
              .delete()
              .eq('contact_id', contact.contactId);
          _load();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(
              SnackBar(content: Text('Failed to delete contact: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return _buildGuestView();
    }

    return _buildProfileView(_profile!);
  }

  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'Log in to view your profile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your account and emergency contacts',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
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
                    onPressed: _goToLogin,
                    child: const Text('Log In',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView(AppUser profile) {
    final initial = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Profile',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green,
                      backgroundImage: profile.photo != null
                          ? NetworkImage('${profile.photo!}?t=${DateTime.now().millisecondsSinceEpoch}')
                          : null,
                      child: profile.photo == null
                          ? Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(profile.email,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionLabel('ACCOUNT'),
                _card([
                  _actionTile(
                    icon: Icons.edit_outlined,
                    iconColor: Colors.orange,
                    title: 'Edit Profile',
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfilePage(profile: profile),
                        ),
                      );
                      if (result == true) await _load();
                    },
                  ),
                  _divider(),
                  _actionTile(
                    icon: Icons.lock_outline,
                    iconColor: Colors.grey[700]!,
                    title: 'Update Password',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UpdatePasswordPage(),
                        ),
                      );
                    },
                  ),
                ]),
                if (profile.isAdmin) ...[
                  const SizedBox(height: 20),
                  _sectionLabel('ADMINISTRATION'),
                  _card([
                    _actionTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: Colors.green,
                      title: 'Admin Dashboard',
                      onTap: () => _goToAdminDashboard(profile),
                    ),
                  ]),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionLabel('EMERGENCY CONTACTS'),
                    if (_contacts.length < 3)
                      TextButton.icon(
                        onPressed: _addContact,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                  ],
                ),
                _card([
                  if (_contacts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No emergency contacts yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    )
                  else
                    for (int i = 0; i < _contacts.length; i++) ...[
                      if (i > 0) _divider(),
                      _contactTile(_contacts[i]),
                    ],
                ]),
                const SizedBox(height: 20),
                _sectionLabel('EMERGENCY'),
                _card([
                  _actionTile(
                    icon: Icons.sos,
                    iconColor: Colors.red,
                    title: 'Emergency Assistance',
                    titleColor: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const EmergencyAssistancePage(),
                        ),
                      );
                    },
                  ),
                  _divider(),
                  _actionTile(
                    icon: Icons.article_outlined,
                    iconColor: Colors.blueGrey,
                    title: 'Emergency History',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencyHistoryPage(),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.05),
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _contactTile(EmergencyContact contact) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.1),
        child: const Icon(Icons.person, color: Colors.green),
      ),
      title: Text(contact.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text('${contact.relationship} · ${contact.contactNumber}',
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => _editContact(contact),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => _deleteContact(contact),
          ),
        ],
      ),
    );
  }
}