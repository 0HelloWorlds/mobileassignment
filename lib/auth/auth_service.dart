import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mob_ass/models/app_user.dart';
import 'dart:typed_data';

final supabase = Supabase.instance.client;

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

bool get isLoggedIn => supabase.auth.currentUser != null;

Future<AppUser?> fetchCurrentProfile() async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final data = await supabase
      .from('user')
      .select()
      .eq('user_id', userId)
      .maybeSingle();

  if (data == null) return null;
  return AppUser.fromJson(data);
}

Future<void> signUpUser({
  required String name,
  required String email,
  required String password,
  required String phoneNumber,
  required String emergencyContactName,
  required String emergencyContactNumber,
  required String emergencyContactRelationship,
  String role = 'user',
}) async {

  try {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'mobapp://login-callback/',
      data: {
        'name': name,
        'phone_number': phoneNumber,
        'role': role,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_number': emergencyContactNumber,
        'emergency_contact_relationship':
        emergencyContactRelationship,
      },
    );

    if (res.user == null) {
      throw AuthException('Sign up failed. Please try again.');
    }

    if (res.user!.identities != null && res.user!.identities!.isEmpty) {
      throw AuthException('This email is already registered. Try another');
    }

  } on AuthApiException catch (e) {
    throw AuthException(e.message);
  }
}

Future<void> createProfileAfterVerification() async {
  final user = supabase.auth.currentUser;

  if (user == null) {
    throw AuthException('You must be logged in.');
  }

  final existingProfile = await supabase
      .from('user')
      .select('user_id')
      .eq('user_id', user.id)
      .maybeSingle();

  if (existingProfile != null) {
    return;
  }

  final metadata = user.userMetadata;

  try {
    await supabase.from('user').insert({
      'user_id': user.id,
      'name': metadata?['name'],
      'email': user.email,
      'role': metadata?['role'] ?? 'user',
      'phone_number': metadata?['phone_number'],
      'status': 'active',
    });

    await supabase.from('emergency_contacts').insert({
      'user_id': user.id,
      'full_name': metadata?['emergency_contact_name'],
      'contact_number': metadata?['emergency_contact_number'],
      'relationship': metadata?['emergency_contact_relationship'],
    });
  } catch (e) {
    throw AuthException(
      'Failed to create profile: $e',
    );
  }
}

Future<void> signInUser({
  required String email,
  required String password,
}) async {
  try {
    await supabase.auth.signInWithPassword(email: email, password: password);
  } on AuthApiException catch (e) {
    throw AuthException(e.message);
  }
  await createProfileAfterVerification();
  final profile = await fetchCurrentProfile();
  if (profile != null && !profile.isActive) {
    await supabase.auth.signOut();
    throw AuthException(
      'This account has been deactivated. Please contact an administrator.',
    );
  }
}

Future<void> signOutUser() async {
  await supabase.auth.signOut();
}

Future<void> updateOwnPassword({
  required String oldPassword,
  required String newPassword,
}) async {
  final email = supabase.auth.currentUser?.email;
  if (email == null) {
    throw AuthException('You must be logged in to update your password.');
  }

  try {
    await supabase.auth.signInWithPassword(email: email, password: oldPassword);
  } on AuthApiException catch (_) {
    throw AuthException('Current password is incorrect.');
  }

  try {
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  } on AuthApiException catch (e) {
    throw AuthException(e.message);
  }
}

Future<String> uploadProfilePhoto(Uint8List imageBytes, String userId,) async {
  final filePath = '$userId.jpg';
  try {
    await supabase.storage
        .from('profile-photos')
        .uploadBinary(
      filePath,
      imageBytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/jpeg',
      ),
    );

    final photoUrl = supabase.storage
        .from('profile-photos')
        .getPublicUrl(filePath);

    await supabase
        .from('user')
        .update({'photo': photoUrl})
        .eq('user_id', userId);

    return photoUrl;
  } catch (e) {
    throw AuthException('Failed to upload profile photo: $e');
  }
}