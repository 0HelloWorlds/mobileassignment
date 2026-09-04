import 'package:flutter/material.dart';
import 'package:mob_ass/auth/auth_service.dart';

class SignUpPage extends StatefulWidget {
  final String role;
  final String title;

  const SignUpPage({
    super.key,
    this.role = 'user',
    this.title = 'Create Account',
  });

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _contactNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _contactRelationshipController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactNameController.dispose();
    _contactNumberController.dispose();
    _contactRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {

      await signUpUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        emergencyContactName: _contactNameController.text.trim(),
        emergencyContactNumber: _contactNumberController.text.trim(),
        emergencyContactRelationship: _contactRelationshipController.text.trim(),
        role: widget.role,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Verification email sent to ${_emailController.text.trim()}. Please verify your email before logging in.',)));
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
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
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionCard(
                  title: 'Account Details',
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[A-Za-z ]+$').hasMatch(v.trim())) {
                          return 'Name can only contain letters';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(
                          r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                        ).hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration:
                      const InputDecoration(labelText: 'Phone Number'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[0-9]{10,11}$').hasMatch(v.trim())) {
                          return 'Phone number must be 10 or 11 digits';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6 || v.length > 12) return 'Password need 6-12 characters';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                          labelText: 'Confirm Password'),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Emergency Contact (required)',
                  subtitle:
                  'Every account needs at least one emergency contact.',
                  children: [
                    TextFormField(
                      controller: _contactNameController,
                      decoration:
                      const InputDecoration(labelText: 'Contact Full Name'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[A-Za-z ]+$').hasMatch(v.trim())) {
                          return 'Name can only contain letters';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _contactNumberController,
                      keyboardType: TextInputType.phone,
                      decoration:
                      const InputDecoration(labelText: 'Contact Number'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final contactNumber = v.trim();
                        final phoneNumber = _phoneController.text.trim();

                        if (!RegExp(r'^[0-9]{10,11}$').hasMatch(contactNumber)) {
                          return 'Contact number must be 10 or 11 digits';
                        }
                        if (contactNumber == phoneNumber) {
                          return 'Cannot be the same as your phone number';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _contactRelationshipController,
                      decoration:
                      const InputDecoration(labelText: 'Relationship'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[A-Za-z ]+$').hasMatch(v.trim())) {
                          return 'Relationship can only contain letters';
                        }
                        return null;
                      },
                    ),
                  ],
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
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Create Account',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          const SizedBox(height: 12),
          for (final child in children) ...[
            child,
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}