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

  Tenant copyWith({int? id, String? name, String? location, bool? isOpen}) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  factory Tenant.fromJson(Map<String, dynamic> json) {
    final data =
        json.containsKey('data') && json['data'] is Map
            ? json['data'] as Map<String, dynamic>
            : json;

    return Tenant(
      id: data['id'],
      name: data['name'],
      location: data['location'] ?? '',
      isOpen: data['isOpen'] == 1 || data['isOpen'] == true,
    );
  }
}
