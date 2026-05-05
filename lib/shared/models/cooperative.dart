class Cooperative {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameFr;
  final String? address;
  final String? phone;
  final String? email;
  final String? ice;
  final String? rc;
  final String? logoUrl;

  Cooperative({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameFr,
    this.address,
    this.phone,
    this.email,
    this.ice,
    this.rc,
    this.logoUrl,
  });

  factory Cooperative.fromJson(Map<String, dynamic> json) {
    return Cooperative(
      id: json['id'],
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      nameFr: json['name_fr'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      ice: json['ice'],
      rc: json['rc'],
      logoUrl: json['logo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'name_fr': nameFr,
      'address': address,
      'phone': phone,
      'email': email,
      'ice': ice,
      'rc': rc,
      'logo_url': logoUrl,
    };
  }
}
