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
  final response = await supabase.functions.invoke('get-user');
  final data = response.data['user'];

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

  final response = await supabase.functions.invoke('create-user');

  if (response.data['error'] != null) {
    throw AuthException('Failed to create profile: ${response.data['error']}');
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

    final response = await supabase.functions.invoke('update-user', body: {
      'photo': photoUrl,
    });

    if (response.data['error'] != null) {
      throw AuthException('Failed to update photo: ${response.data['error']}');
    }

    return photoUrl;
  } catch (e) {
    throw AuthException('Failed to upload profile photo: $e');
  }
}