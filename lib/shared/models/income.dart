class Income {
  final String id;
  final String cooperativeId;
  final String category;
  final double amount;
  final DateTime date;
  final String? note;
  final String source; // 'manual' or 'invoice'
  final String? documentId;
  final DateTime createdAt;

  Income({
    required this.id,
    required this.cooperativeId,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    required this.source,
    this.documentId,
    required this.createdAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      cooperativeId: json['cooperative_id'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      note: json['note'],
      source: json['source'] ?? 'manual',
      documentId: json['document_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'cooperative_id': cooperativeId,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'source': source,
      'document_id': documentId,
    };
  }
}
