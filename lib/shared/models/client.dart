class Client {
  final String id;
  final String cooperativeId;
  final String name;
  final String phone;
  final String address;
  final String? email;

  Client({
    required this.id,
    required this.cooperativeId,
    required this.name,
    required this.phone,
    required this.address,
    this.email,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      cooperativeId: json['cooperative_id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cooperative_id': cooperativeId,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
    };
  }
}
