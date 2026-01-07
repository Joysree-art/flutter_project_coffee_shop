import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/user_model.dart';
import '../admin/products/product_model.dart';


class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;
  static UserModel? currentUser;

  // ================= LOAD USER PROFILE =================
  static Future<void> loadUserProfile() async {
    try {
      final authUser = client.auth.currentUser;
      if (authUser == null) {
        currentUser = null;
        return;
      }

      final profile = await client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (profile != null && profile is Map<String, dynamic>) {
        currentUser = UserModel.fromMap(profile);
      }
    } catch (e) {
      print('Load user profile error: $e');
    }
  }

  // ================= LOGIN =================
  static Future<String?> login(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session == null || res.user == null) return 'Login failed';

      await loadUserProfile();
      if (currentUser == null) return 'User profile not found';

      return currentUser!.role == 'admin' ? 'admin' : 'user';
    } catch (e) {
      return e.toString();
    }
  }

  // ================= REGISTER =================
  static Future<String?> register(
      String name, String email, String password) async {
    try {
      final res = await client.auth.signUp(email: email, password: password);
      if (res.user == null) return 'Registration failed';

      await client.from('users').insert({
        'id': res.user!.id,
        'name': name,
        'email': email,
        'role': 'user',
      });

      await loadUserProfile();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    await client.auth.signOut();
    currentUser = null;
  }

  // ================= ROLE CHECK =================
  static bool isAdmin() => currentUser?.role == 'admin';

  // ================= UPDATE PROFILE =================
  static Future<void> updateProfile({
    String? name,
    String? address,
    String? avatarUrl,
  }) async {
    if (currentUser == null) return;

    try {
      await client.from('users').update({
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }).eq('id', currentUser!.id);

      await loadUserProfile();
    } catch (e) {
      print('Update profile error: $e');
    }
  }

  // ================= UPLOAD AVATAR (Mobile) =================
  static Future<String?> uploadAvatar(File file) async {
    if (currentUser == null) return null;

    try {
      final fileName =
          '${currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.png';

      await client.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      return client.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      print('Upload avatar error: $e');
      return null;
    }
  }

  // ================= UPLOAD AVATAR (Web Support) =================
  static Future<String?> uploadWebAvatar(Uint8List bytes) async {
    if (currentUser == null) return null;

    try {
      final fileName =
          '${currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.png';

      await client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return client.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      print('Upload web avatar error: $e');
      return null;
    }
  }

  // ================= UPLOAD PRODUCT IMAGE =================
  static Future<String?> uploadImage(File file, String folder) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      await client.storage.from('products').upload(
            '$folder/$fileName',
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      return client.storage.from('products').getPublicUrl('$folder/$fileName');
    } catch (e) {
      print('Upload image error: $e');
      return null;
    }
  }

  static Future<String?> uploadWebImage(Uint8List bytes, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';

      await client.storage.from('products').uploadBinary(
            '$folder/$fileName',
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      return client.storage.from('products').getPublicUrl('$folder/$fileName');
    } catch (e) {
      print('Upload web image error: $e');
      return null;
    }
  }

  // ================= CHANGE PASSWORD =================
  static Future<void> changePassword(String newPassword) async {
    try {
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      print('Change password error: $e');
    }
  }

  // ================= PRODUCTS CRUD =================
  static Future<List<Product>> getProducts() async {
    try {
      final res =
          await client.from('products').select().order('id', ascending: true);
      if (res is! List) return [];
      return res
          .map((e) => Product.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get products error: $e');
      return [];
    }
  }

  static Future<bool> addProduct(Product product) async {
    try {
      await client.from('products').insert(product.toMap());
      return true;
    } catch (e) {
      print('Add product error: $e');
      return false;
    }
  }

  static Future<bool> updateProduct(Product product) async {
    if (product.id == null) return false;
    try {
      await client.from('products').update(product.toMap()).eq('id', product.id!);
      return true;
    } catch (e) {
      print('Update product error: $e');
      return false;
    }
  }

  static Future<bool> deleteProduct(int? id) async {
    if (id == null) return false;
    try {
      await client.from('products').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Delete product error: $e');
      return false;
    }
  }

  // ================= USER ORDER HISTORY =================
  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      if (currentUser == null) return [];

      final res = await client
          .from('orders')
          .select('id, total_amount, status, created_at, address')
          .eq('user_id', currentUser!.id)
          .order('id', ascending: false);

      if (res is! List) return [];
      return res.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Get user orders error: $e');
      return [];
    }
  }

  // ================= ADMIN ORDERS =================
  static Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final res = await client
          .from('orders')
          .select('id, user_id, status, total_amount, address, users(email)')
          .order('id', ascending: false);

      if (res is! List) return [];

      return res.map((e) {
        final map = e as Map<String, dynamic>;
        map['user_email'] = map['users']?['email'] ?? 'Unknown';
        return map;
      }).toList();
    } catch (e) {
      print('Get orders error: $e');
      return [];
    }
  }

  static Future<bool> updateOrderStatus(int id, String status) async {
    try {
      await client.from('orders').update({'status': status}).eq('id', id);
      return true;
    } catch (e) {
      print('Update order status error: $e');
      return false;
    }
  }

  // ================= PLACE ORDER =================
  static Future<bool> placeOrder({
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    if (currentUser == null) return false;

    try {
      await client.from('orders').insert({
        'user_id': currentUser!.id,
        'total_amount': totalAmount,
        'status': 'pending',
        'address': currentUser!.address ?? '',
        'items': items,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Place order error: $e');
      return false;
    }
  }
}
