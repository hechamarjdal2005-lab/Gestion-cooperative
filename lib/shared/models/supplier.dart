class Supplier {
  final String id;
  final String cooperativeId;
  final String name;
  final String phone;
  final String address;
  final String? email;

  Supplier({
    required this.id,
    required this.cooperativeId,
    required this.name,
    required this.phone,
    required this.address,
    this.email,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      cooperativeId: json['cooperative_id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      email: json['email'],
    );
  }
}
