import 'package:flutter/material.dart';
import 'package:mob_ass/auth/auth_service.dart';
import 'package:mob_ass/models/app_user.dart';

class AdminAccountDetailPage extends StatefulWidget {
  final AppUser admin;

  const AdminAccountDetailPage({
    super.key,
    required this.admin,
  });

  @override
  State<AdminAccountDetailPage> createState() =>
      _AdminAccountDetailPageState();
}

class _AdminAccountDetailPageState
    extends State<AdminAccountDetailPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  late bool _isActive;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.admin.name);

    _phoneController =
        TextEditingController(text: widget.admin.phoneNumber);

    _isActive = widget.admin.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final response = await supabase.functions.invoke('admin-update-user', body: {
        'target_user_id': widget.admin.id,
        'name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'status': _isActive ? 'active' : 'inactive',
      });

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin updated successfully!'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update admin: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
        title: const Text('Admin Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }

                    if (!RegExp(r'^[A-Za-z ]+$')
                        .hasMatch(v.trim())) {
                      return 'Name can only contain letters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  initialValue: widget.admin.email,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }

                    if (!RegExp(r'^[0-9]{10,11}$')
                        .hasMatch(v.trim())) {
                      return 'Phone number must be 10 or 11 digits';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.grey.shade300),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Account Active'),
                    subtitle: Text(
                      _isActive
                          ? 'Admin can log in normally'
                          : 'Admin is blocked from logging in',
                    ),
                    value: _isActive,
                    onChanged: (v) {
                      setState(() {
                        _isActive = v;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Registered: ${widget.admin.createdAt.toLocal()}'
                      .split('.')
                      .first,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}