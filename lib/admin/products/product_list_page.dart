import 'package:flutter/material.dart';
import 'add_product_page.dart';
import 'edit_product_page.dart';
import '../../../services/supabase_service.dart';
import 'product_model.dart';
import '../../utils/cart.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Product> products = [];
  bool loading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    checkRoleAndFetch();
  }

  Future<void> checkRoleAndFetch() async {
    setState(() => loading = true);
    isAdmin = SupabaseService.isAdmin();
    products = await SupabaseService.getProducts();
    setState(() => loading = false);
  }

  Future<void> fetchProducts() async {
    setState(() => loading = true);
    products = await SupabaseService.getProducts();
    setState(() => loading = false);
  }

  Future<void> deleteProduct(int? id) async {
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await SupabaseService.deleteProduct(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted')),
      );
      fetchProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 40) / 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6),
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.brown,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text('No products found'))
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final hasImage = product.imageUrl != null &&
                          product.imageUrl!.isNotEmpty;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ================= IMAGE + ADMIN ACTIONS =================
                            Stack(
                              children: [
                                Container(
                                  height: itemWidth,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                    color: Colors.grey[200],
                                    image: hasImage
                                        ? DecorationImage(
                                            image: NetworkImage(
                                                product.imageUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: !hasImage
                                      ? const Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 30,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : null,
                                ),

                                // ================= ADMIN EDIT / DELETE =================
                                if (isAdmin)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.white,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.edit,
                                                size: 18,
                                                color: Colors.blue),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EditProductPage(
                                                          product: product),
                                                ),
                                              ).then((_) => fetchProducts());
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.white,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.delete,
                                                size: 18,
                                                color: Colors.red),
                                            onPressed: () =>
                                                deleteProduct(product.id),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            // ================= PRODUCT INFO =================
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '৳${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown),
                                  ),

                                  // ================= USER CART =================
                                  if (!isAdmin)
                                    IconButton(
                                      icon: const Icon(
                                          Icons.add_shopping_cart,
                                          color: Colors.green),
                                      onPressed: () {
                                        Cart.add(product);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  '${product.name} added to cart')),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.brown,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddProductPage(),
                  ),
                ).then((_) => fetchProducts());
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
