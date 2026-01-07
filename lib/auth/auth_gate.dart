import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../auth/login_page.dart';
import '../users/home_page.dart';
import '../admin/admin_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // ✅ User already logged in → load profile
      await SupabaseService.loadUserProfile();
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = Supabase.instance.client.auth.currentSession;
    final user = SupabaseService.currentUser;

    // ❌ Not logged in
    if (session == null || user == null) {
      return const LoginPage();
    }

    // ✅ Logged in
    // 🔐 Role-based navigation
    if (user.isAdmin) {
      return const AdminPage();
    } else {
      return const HomePage();
    }
  }
}