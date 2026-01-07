// utils/cart.dart
import '../admin/products/product_model.dart';

class Cart {
  static final List<Product> items = [];

  static void add(Product product) {
    final index = items.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      items[index].quantity += 1; // increase quantity if already in cart
    } else {
      final p = Product(
        id: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrl,
        quantity: 1,
      );
      items.add(p);
    }
  }

  static void remove(Product product) {
    items.removeWhere((p) => p.id == product.id);
  }

  static void clear() {
    items.clear();
  }

  static double totalAmount() {
    double total = 0;
    for (var item in items) {
      total += item.price * item.quantity;
    }
    return total;
  }
}
