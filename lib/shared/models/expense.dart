class Expense {
  final String id;
  final String cooperativeId;
  final String category;
  final double amount;
  final DateTime date;
  final String? note;

  Expense({
    required this.id,
    required this.cooperativeId,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      cooperativeId: json['cooperative_id'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      note: json['note'],
    );
  }
}
