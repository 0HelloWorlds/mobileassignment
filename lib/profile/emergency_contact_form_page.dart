import 'package:flutter/material.dart';
import 'package:mob_ass/auth/auth_service.dart';
import 'package:mob_ass/models/emergency_contact.dart';

class EmergencyContactFormPage extends StatefulWidget {
  final EmergencyContact? existing;
  final String personalPhoneNumber;

  const EmergencyContactFormPage({
    super.key,
    this.existing,
    required this.personalPhoneNumber,
  });

  @override
  State<EmergencyContactFormPage> createState() =>
      _EmergencyContactFormPageState();
}

class _EmergencyContactFormPageState extends State<EmergencyContactFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _numberController;
  late final TextEditingController _relationshipController;

  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.fullName ?? '');
    _numberController = TextEditingController(text: widget.existing?.contactNumber ?? '');
    _relationshipController = TextEditingController(text: widget.existing?.relationship ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    final emergencyNumber = _numberController.text.trim();
    final personalNumber = widget.personalPhoneNumber.trim();

    setState(() => _saving = true);
    try {

      final data = await supabase
          .from('emergency_contacts')
          .select('contact_id, contact_number')
          .eq('user_id', userId);

      final contacts = data as List;

      if (!_isEditing && contacts.length >= 3) {
        throw Exception(
          'You can have a maximum of 3 emergency contacts.',
        );
      }

      if (emergencyNumber == personalNumber) {
        throw Exception(
          'Emergency contact number cannot be the same as your personal number.',
        );
      }

      final duplicate = contacts.any((contact) {
        if (_isEditing &&
            contact['contact_id'] == widget.existing!.contactId) {
          return false;
        }

        return contact['contact_number'].toString().trim() ==
            emergencyNumber;
      });

      if (duplicate) {
        throw Exception(
          'This emergency contact number already exists.',
        );
      }

      if (_isEditing) {
        await supabase
            .from('emergency_contacts')
            .update({
          'full_name': _nameController.text.trim(),
          'contact_number': emergencyNumber,
          'relationship': _relationshipController.text.trim(),
        }).eq(
          'contact_id',
          widget.existing!.contactId,
        );
      }

      else {
        await supabase.from('emergency_contacts').insert({
          'user_id': userId,
          'full_name': _nameController.text.trim(),
          'contact_number': emergencyNumber,
          'relationship': _relationshipController.text.trim(),
        });
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
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
        title: Text(
          _isEditing
              ? 'Edit Emergency Contact'
              : 'Add Emergency Contact',
        ),
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
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
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
                TextFormField(
                  controller: _relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    hintText: 'Mother, Wife, Friend',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
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
                        : Text(_isEditing
                          ? 'Save Changes'
                          : 'Add Contact',
                      style: const TextStyle(
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