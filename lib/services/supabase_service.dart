import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/user_model.dart';
import '../admin/products/product_model.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;
  static UserModel? currentUser;

  // ================= LOGIN =================
  static Future<String?> login(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session == null || res.user == null) return 'Login failed';

      final profile = await client
          .from('users')
          .select()
          .eq('id', res.user!.id)
          .maybeSingle();

      if (profile == null || profile is! Map<String, dynamic>) return 'User profile not found';

      String role = profile['role']?.toString() ?? 'user';
      currentUser = UserModel(
        id: res.user!.id,
        email: profile['email'] ?? '',
        role: role,
        name: profile['name'] ?? '',
      );

      return role == 'admin' ? 'admin' : 'user';
    } catch (e) {
      return e.toString();
    }
  }

  // ================= REGISTER =================
  static Future<String?> register(String name, String email, String password) async {
    try {
      final res = await client.auth.signUp(email: email, password: password);
      if (res.user == null) return 'Registration failed';

      await client.from('users').insert({
        'id': res.user!.id,
        'name': name,
        'email': email,
        'role': 'user',
      });

      currentUser = UserModel(
        id: res.user!.id,
        email: email,
        role: 'user',
        name: name,
      );
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

  // ================= PRODUCTS =================
  static Future<List<Product>> getProducts() async {
    try {
      final res = await client.from('products').select().order('id', ascending: true);
      if (res == null || res is! List) return [];
      return res.map((e) => Product.fromMap(e as Map<String, dynamic>)).toList();
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

  // ================= UPLOAD IMAGE (Mobile) =================
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

      // Direct String return
      final url = client.storage.from('products').getPublicUrl('$folder/$fileName');
      return url;
    } catch (e) {
      print('Upload image error: $e');
      return null;
    }
  }

  // ================= UPLOAD IMAGE (Web) =================
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

      // Direct String return
      final url = client.storage.from('products').getPublicUrl('$folder/$fileName');
      return url;
    } catch (e) {
      print('Upload web image error: $e');
      return null;
    }
  }

  // ================= ORDERS =================
  static Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final res = await client
          .from('orders')
          .select('id, user_id, status, users(email)')
          .order('id', ascending: false);

      if (res == null || res is! List) return [];

      return res.map((e) {
        final map = e as Map<String, dynamic>;
        map['user_email'] = (map['users']?['email'] ?? 'Unknown');
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

  // ================= REFRESH CURRENT USER =================
  static Future<void> refreshUser() async {
    try {
      final session = client.auth.currentSession;
      final user = session?.user;
      if (user == null) {
        currentUser = null;
        return;
      }
      final profile =
          await client.from('users').select().eq('id', user.id).maybeSingle();
      if (profile != null && profile is Map<String, dynamic>) {
        currentUser = UserModel.fromMap(profile);
      }
    } catch (e) {
      print('Refresh user error: $e');
    }
  }
}
