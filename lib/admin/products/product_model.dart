class Product {
  final int? id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? description;
  int quantity;

  Product({
    this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.description,
    this.quantity = 1,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'],
      description: map['description'],
      quantity: 1,
    );
  }

  /// ❗ INSERT / UPDATE এর সময় id পাঠানো যাবে না
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'description': description,
    };
  }
}
