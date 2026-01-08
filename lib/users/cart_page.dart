import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../utils/cart.dart';
import '../users/home_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isLoading = false;

  double get totalAmount => Cart.totalAmount();

  Future<void> checkout() async {
    if (Cart.items.isEmpty) return;

    setState(() => isLoading = true);

    // Prepare items for backend
    final items = Cart.items
        .map((p) => {
              'product_id': p.id,
              'name': p.name,
              'price': p.price,
              'quantity': p.quantity,
            })
        .toList();

    final success = await SupabaseService.placeOrder(
      totalAmount: totalAmount,
      items: items,
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      Cart.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = Cart.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      backgroundColor: const Color(0xFFB08968) , // ☕ COFFEE COLOR ADDED
      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(item.name),
                          subtitle:
                              Text('Price: ${item.price} x ${item.quantity}'),
                          trailing:
                              Text('Total: ${item.price * item.quantity}'),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: $totalAmount',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: isLoading ? null : checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                               'Checkout',
                                style: TextStyle(color: Colors.white), // ✅ white text
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
