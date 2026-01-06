import 'package:flutter/material.dart'; 
import 'add_product_page.dart';
import 'edit_product_page.dart';
import '../../../services/supabase_service.dart';
import 'product_model.dart';

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

  Future<void> deleteProduct(int? id) async {
    if (id == null) return;
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

  Future<void> fetchProducts() async {
    setState(() => loading = true);
    products = await SupabaseService.getProducts();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 40) / 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6), // light coffee color
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.brown,
        automaticallyImplyLeading: false,
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
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Stack(
                              children: [
                                // ===== IMAGE =====
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
                                            image: NetworkImage(product.imageUrl!),
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
                                        ))
                                      : null,
                                ),

                                // ===== ADMIN BUTTONS =====
                                if (isAdmin)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white70,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 20,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EditProductPage(product: product),
                                                ),
                                              ).then((_) => fetchProducts());
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white70,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => deleteProduct(product.id),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            // ===== NAME, PRICE & USER CART BUTTON =====
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '৳${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown),
                                  ),
                                  if (!isAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                                      onPressed: () {
                                        // Add to cart logic here
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${product.name} added to cart')),
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
      // ===== ADD BUTTON (ONLY FOR ADMIN) =====
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
