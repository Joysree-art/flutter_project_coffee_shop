import 'package:flutter/material.dart';
import 'products/product_list_page.dart';
import 'orders/admin_orders_page.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int selectedIndex = 0;
  UserModel? user;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    /// 🔥 FIX HERE
    await SupabaseService.loadUserProfile();
    setState(() {
      user = SupabaseService.currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user!.role != 'admin') {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }

    final pages = [
      const ProductListPage(),
      const AdminOrdersPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedIndex == 0 ? 'Products' : 'Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseService.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
          )
        ],
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.list), label: 'Products'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt), label: 'Orders'),
        ],
        onTap: (index) => setState(() => selectedIndex = index),
      ),
    );
  }
}
