class DocumentItem {
  final String id;
  final String documentId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double total;
  final String? productName;

  DocumentItem({
    required this.id,
    required this.documentId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.productName,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json['id'],
      documentId: json['document_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      productName: json['products']?['name'],
    );
  }
}
