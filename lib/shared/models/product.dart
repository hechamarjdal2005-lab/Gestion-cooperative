class Product {
  final String id;
  final String cooperativeId;
  final String? supplierId;
  final String name;
  final double price;
  final int stock;
  final int minStock;
  final String? photoUrl;

  Product({
    required this.id,
    required this.cooperativeId,
    this.supplierId,
    required this.name,
    required this.price,
    required this.stock,
    this.minStock = 0,
    this.photoUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      cooperativeId: json['cooperative_id'],
      supplierId: json['supplier_id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      stock: json['stock'],
      minStock: json['min_stock'] ?? 0,
      photoUrl: json['photo_url'],
    );
  }
}
