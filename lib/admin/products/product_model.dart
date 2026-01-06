class Product {
  int? id;
  String name;
  String description;
  double price;
  String? imageUrl;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
  });

  // From Supabase row (Map<String, dynamic>) to Product object
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] != null
          ? (map['price'] is int
              ? (map['price'] as int).toDouble()
              : map['price'] as double)
          : 0,
      imageUrl: map['image_url'], // Note: Supabase column name should match
    );
  }

  // Convert Product object to Map to insert/update Supabase
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
    };
  }
}
