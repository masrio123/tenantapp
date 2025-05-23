class Tenant {
  final int id;
  final String name;
  final String location;
  final bool isOpen;

  Tenant({
    required this.id,
    required this.name,
    required this.location,
    required this.isOpen,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      isOpen: json['isOpen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'isOpen': isOpen,
    };
  }

  @override
  String toString() {
    return 'Tenant(id: $id, name: $name, location: $location, isOpen: $isOpen)';
  }
}