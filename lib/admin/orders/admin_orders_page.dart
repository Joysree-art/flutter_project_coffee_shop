import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});
  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<Map<String, dynamic>> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => loading = true);
    orders = await SupabaseService.getOrders();
    setState(() => loading = false);
  }

  Future<void> updateStatus(int id, String newStatus) async {
    final success = await SupabaseService.updateOrderStatus(id, newStatus);
    if (success) fetchOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Status updated' : 'Failed to update status')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text('Order #${order['id']}'),
                    subtitle: Text('User: ${order['user_email'] ?? 'Unknown'}\nStatus: ${order['status']}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => updateStatus(order['id'], value),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'pending', child: Text('Pending')),
                        PopupMenuItem(value: 'processing', child: Text('Processing')),
                        PopupMenuItem(value: 'completed', child: Text('Completed')),
                        PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      ],
                      child: Icon(Icons.more_vert, color: Colors.blue.shade700),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
