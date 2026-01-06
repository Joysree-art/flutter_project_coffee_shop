import 'supabase_service.dart';
import '../admin/products/product_model.dart';

class ProductService {
  // Wrapper for Supabase product operations

  static Future<List<Product>> fetchProducts() async {
    return await SupabaseService.getProducts();
  }

  static Future<bool> addProduct(Product product) async {
    return await SupabaseService.addProduct(product);
  }

  static Future<bool> updateProduct(Product product) async {
    return await SupabaseService.updateProduct(product);
  }

  static Future<bool> deleteProduct(int? id) async {
    return await SupabaseService.deleteProduct(id);
  }
}