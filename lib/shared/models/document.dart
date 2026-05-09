class AppDocument {
  final String id;
  final String cooperativeId;
  final String type;
  final String number;
  final String? name;
  final String? clientId;
  final String? supplierId;
  final String status;
  final double total;
  final double discount;
  final double tvaRate;
  final double tvaAmount;
  final double deliveryFees;
  final DateTime date;
  final String? notes;
  final String? paymentMethod;
  final String? deliveryLocation;
  final String? deliveryDelay;
  final String? linkedOrderRef;
  final String? signatureClient;
  final String? additionalInfo;
  final String? clientName;
  final String? clientPhone;
  final String? clientAddress;
  final String? supplierName;

  AppDocument({
    required this.id,
    required this.cooperativeId,
    required this.type,
    required this.number,
    this.name,
    this.clientId,
    this.supplierId,
    required this.status,
    required this.total,
    this.discount = 0,
    this.tvaRate = 0,
    this.tvaAmount = 0,
    this.deliveryFees = 0,
    required this.date,
    this.notes,
    this.paymentMethod,
    this.deliveryLocation,
    this.deliveryDelay,
    this.linkedOrderRef,
    this.signatureClient,
    this.additionalInfo,
    this.clientName,
    this.clientPhone,
    this.clientAddress,
    this.supplierName,
  });

  factory AppDocument.fromJson(Map<String, dynamic> json) {
    return AppDocument(
      id: json['id'],
      cooperativeId: json['cooperative_id'],
      type: json['type'],
      number: json['number'],
      name: json['name'],
      clientId: json['client_id'],
      supplierId: json['supplier_id'],
      status: json['status'],
      total: (json['total'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      tvaRate: (json['tva_rate'] as num?)?.toDouble() ?? 0,
      tvaAmount: (json['tva_amount'] as num?)?.toDouble() ?? 0,
      deliveryFees: (json['delivery_fees'] as num?)?.toDouble() ?? 0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      notes: json['notes'],
      paymentMethod: json['payment_method'],
      deliveryLocation: json['delivery_location'],
      deliveryDelay: json['delivery_delay'],
      linkedOrderRef: json['linked_order_ref'],
      signatureClient: json['signature_client'],
      additionalInfo: json['additional_info'],
      clientName: json['clients']?['name'],
      clientPhone: json['clients']?['phone'],
      clientAddress: json['clients']?['address'],
      supplierName: json['suppliers']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cooperative_id': cooperativeId,
      'type': type,
      'number': number,
      'name': name,
      'client_id': clientId,
      'supplier_id': supplierId,
      'status': status,
      'total': total,
      'discount': discount,
      'tva_rate': tvaRate,
      'tva_amount': tvaAmount,
      'delivery_fees': deliveryFees,
      'date': date.toIso8601String(),
      'notes': notes,
      'payment_method': paymentMethod,
      'delivery_location': deliveryLocation,
      'delivery_delay': deliveryDelay,
      'linked_order_ref': linkedOrderRef,
      'signature_client': signatureClient,
      'additional_info': additionalInfo,
    };
  }

  List<DocumentItem> items = [];

  String get typeLabel {
    switch (type) {
      case 'FAC':
        return 'FACTURE';
      case 'BDL':
        return 'BON DE LIVRAISON';
      case 'DEV':
        return 'DEVIS';
      default:
        return type;
    }
  }
}

class DocumentItem {
  final String? id;
  final String? documentId;
  final String? productId;
  final String productRef;
  final String description;
  final int quantity;
  final String unit;
  final double unitPrice;
  final String? productName;

  DocumentItem({
    this.id,
    this.documentId,
    this.productId,
    this.productRef = '',
    this.description = '',
    this.quantity = 1,
    this.unit = 'Piece',
    this.unitPrice = 0,
    this.productName,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json['id'],
      documentId: json['document_id'],
      productId: json['product_id'],
      productRef: json['product_ref'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 1,
      unit: json['unit'] ?? 'Piece',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      productName: json['products']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'product_id': productId,
      'product_ref': productRef,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
    };
  }

  double get total => quantity * unitPrice;
}
