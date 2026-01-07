class Product {
  final int? id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? description; // add this
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
      description: map['description'], // from DB
      quantity: 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'description': description, // to DB
    };
  }
}
