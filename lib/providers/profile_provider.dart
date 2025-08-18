import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../model/profile_model.dart';

class ProfileNotifier extends StateNotifier<Profile?> {
  ProfileNotifier() : super(null);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get(const GetOptions(source: Source.serverAndCache));
    if (doc.exists && doc.data() != null) {
      state = Profile.fromMap(doc.data()!);
    }
  }

  Future<void> setProfile({
    required String name,
    required String mobile,
    required String address,
    File? imageFile,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? imageUrl = state?.imageUrl;

      if (imageFile != null) {
        final ref = _storage.ref('profile_images/${user.uid}');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'mobile': mobile,
        'address': address,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      state = Profile(
        name: name,
        mobile: mobile,
        address: address,
        imageUrl: imageUrl,
        localImagePath: imageFile?.path,
      );
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> updateProfileImage(File imageFile) async {
    final current = state;
    if (current == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = _storage.ref('profile_images/${user.uid}');
      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = current.copyWith(
        imageUrl: imageUrl,
        localImagePath: imageFile.path,
      );
    } catch (e) {
      throw Exception('Failed to update image: $e');
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, Profile?>((ref) {
  final notifier = ProfileNotifier();
  notifier.loadProfile(); // warm cache on app start
  return notifier;
});
