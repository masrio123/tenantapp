class TenantLocation {
  final int id;
  final String locationName;

  TenantLocation({required this.id, required this.locationName});

  factory TenantLocation.fromJson(Map<String, dynamic> json) {
    return TenantLocation(
      id: json['id'],
      locationName: json['location_name'],
    );
  }
}