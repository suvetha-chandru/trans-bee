import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:trans_bee/model/profile_model.dart';
import 'package:trans_bee/providers/profile_provider.dart';
import 'package:trans_bee/screens/login_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  bool _isEditing = false;
  bool _isLoading = false;
  File? _tempImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile?.name ?? '');
    _mobileController = TextEditingController(text: profile?.mobile ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _tempImageFile = File(pickedFile.path);
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        final profile = ref.read(profileProvider);
        _nameController.text = profile?.name ?? '';
        _mobileController.text = profile?.mobile ?? '';
        _addressController.text = profile?.address ?? '';
        _tempImageFile = null;
      }
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(profileProvider.notifier).setProfile(
            name: _nameController.text.trim(),
            mobile: _mobileController.text.trim(),
            address: _addressController.text.trim(),
            imageFile: _tempImageFile,
          );

      setState(() {
        _isEditing = false;
        _tempImageFile = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      // Ensure we land back on LoginPage for a fresh session
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileImage(Profile? profile) {
    if (_isLoading) return const CircularProgressIndicator();

    if (_tempImageFile != null) {
      return ClipOval(
        child: Image.file(
          _tempImageFile!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    if (profile?.imageUrl != null && profile!.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profile.imageUrl!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              width: 120,
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const CircleAvatar(
              radius: 60,
              child: Icon(Icons.person, size: 60),
            );
          },
        ),
      );
    }

    return const CircleAvatar(
      radius: 60,
      child: Icon(Icons.person, size: 60),
    );
  }

  Widget _buildEditForm(Profile? profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _buildProfileImage(profile),
                if (_isEditing)
                  const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.edit, size: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _mobileController,
            decoration: const InputDecoration(labelText: 'Mobile'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Address'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color.fromARGB(255, 50, 68, 183),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Changes',
                    style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : _toggleEdit,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(Profile? profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileImage(profile),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Name'),
            subtitle: Text(profile?.name ?? 'Not set'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Mobile Number'),
            subtitle: Text(profile?.mobile ?? 'Not set'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Address'),
            subtitle: Text(profile?.address ?? 'Not set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          // logout button on the left (as requested earlier)
          icon: const Icon(Icons.logout),
          onPressed: _isLoading ? null : _logout,
          tooltip: 'Logout',
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: _isEditing ? _buildEditForm(profile) : _buildProfileView(profile),
    );
  }
}

