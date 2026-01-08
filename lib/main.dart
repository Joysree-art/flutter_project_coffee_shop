import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/welcome_page.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'users/home_page.dart';
import 'admin/admin_page.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kydjmrakfgzpykwleeqx.supabase.co',
    anonKey: 'sb_publishable_F9F7DLD_dUVYIBbi2mXRlA_C8MbPXQH',
  );

  
  await SupabaseService.loadUserProfile(); 

  runApp(const CoffeeShopApp());
}

class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    Widget initialPage = const WelcomePage();

    // If user is already logged in, redirect
    if (SupabaseService.currentUser != null) {
      if (SupabaseService.isAdmin()) {
        initialPage = const AdminPage();
      } else {
        initialPage = const HomePage();
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coffee Shop',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: initialPage,
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}
