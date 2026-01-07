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
      SnackBar(
        content: Text(success ? 'Status updated' : 'Failed to update status'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Orders')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No orders yet'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text('Order #${order['id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User: ${order['user_email'] ?? 'Unknown'}'),
                            Text('Address: ${order['address'] ?? 'Not provided'}'),
                            Text('Total: \$${order['total_amount'] ?? 0}'),
                            Text('Status: ${order['status']}'),
                            Text('Created At: ${order['created_at'] ?? 'Unknown'}'),
                          ],
                        ),
                        isThreeLine: false,
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
