class AppDocument {
  final String id;
  final String cooperativeId;
  final String type;
  final String number;
  final String? clientId;
  final String? supplierId;
  final String status;
  final double total;
  final double discount;
  final DateTime date;
  final String? notes;
  final String? clientName;
  final String? supplierName;

  AppDocument({
    required this.id,
    required this.cooperativeId,
    required this.type,
    required this.number,
    this.clientId,
    this.supplierId,
    required this.status,
    required this.total,
    this.discount = 0,
    required this.date,
    this.notes,
    this.clientName,
    this.supplierName,
  });

  factory AppDocument.fromJson(Map<String, dynamic> json) {
    return AppDocument(
      id: json['id'],
      cooperativeId: json['cooperative_id'],
      type: json['type'],
      number: json['number'],
      clientId: json['client_id'],
      supplierId: json['supplier_id'],
      status: json['status'],
      total: (json['total'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      clientName: json['clients']?['name'],
      supplierName: json['suppliers']?['name'],
    );
  }
}
