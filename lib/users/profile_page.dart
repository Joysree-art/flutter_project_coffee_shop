import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import 'order_history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final user = SupabaseService.currentUser;
    nameCtrl.text = user?.name ?? '';
    addressCtrl.text = user?.address ?? '';
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    if (kIsWeb) {
      final result = await picker.pickImage(source: ImageSource.gallery);
      if (result == null) return;

      setState(() => loading = true);
      final bytes = await result.readAsBytes();
      final url = await SupabaseService.uploadWebAvatar(bytes);

      if (url != null) {
        await SupabaseService.updateProfile(avatarUrl: url);
        await SupabaseService.loadUserProfile();
        setState(() {});
      }

      setState(() => loading = false);
    } else {
      final img = await picker.pickImage(source: ImageSource.gallery);
      if (img == null) return;

      setState(() => loading = true);
      final url = await SupabaseService.uploadAvatar(File(img.path));

      if (url != null) {
        await SupabaseService.updateProfile(avatarUrl: url);
        await SupabaseService.loadUserProfile();
        setState(() {});
      }

      setState(() => loading = false);
    }
  }

  // ================= SAVE PROFILE =================
  Future<void> saveProfile() async {
    final name = nameCtrl.text.trim();
    final address = addressCtrl.text.trim();

    if (name.isEmpty && address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name বা Address দিতে হবে')),
      );
      return;
    }

    setState(() => loading = true);

    await SupabaseService.updateProfile(
      name: name.isNotEmpty ? name : null,
      address: address.isNotEmpty ? address : null,
    );

    await SupabaseService.loadUserProfile();

    // UI refresh
    nameCtrl.text = SupabaseService.currentUser?.name ?? '';
    addressCtrl.text = SupabaseService.currentUser?.address ?? '';
    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  // ================= BUILD AVATAR HELPER =================
  Widget buildAvatar({double radius = 50}) {
    final user = SupabaseService.currentUser;
    final avatarUrl = user?.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundImage:
          (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
      child: (avatarUrl == null || avatarUrl.isEmpty)
          ? Icon(Icons.person, size: radius)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  // ================= PROFILE PICTURE =================
                  Center(
                    child: GestureDetector(
                      onTap: pickImage,
                      child: buildAvatar(radius: 50), // same size
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ================= NAME =================
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ================= EMAIL =================
                  Text('Email: ${user.email}'),
                  const SizedBox(height: 10),

                  // ================= ADDRESS =================
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ================= SAVE BUTTON =================
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save Profile'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ================= ORDER HISTORY BUTTON =================
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Order History'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderHistoryPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),

                  // ================= PROFILE INFO =================
                  Text(
                    'Profile Info:',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  Center(child: buildAvatar(radius: 50)), // same size

                  const SizedBox(height: 10),
                  Text('Name: ${user.name}'),
                  Text('Email: ${user.email}'),
                  Text('Address: ${user.address ?? '-'}'),
                ],
              ),
            ),
    );
  }
}
