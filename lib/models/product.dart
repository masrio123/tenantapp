class Product {
  final int id;
  final String name;
  final int price;
  final bool isAvailable;
  final int categoryId;
  final int tenantId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.categoryId,
    required this.tenantId,
  });

  factory Product.fromJson(
    Map<String, dynamic> json, {
    int? defaultCategoryId,
    int? defaultTenantId,
  }) {
    int parsedPrice;
    if (json['price'] is String) {
      parsedPrice = double.tryParse(json['price'])?.toInt() ?? 0;
    } else {
      parsedPrice = (json['price'] as num?)?.toInt() ?? 0;
    }

    return Product(
      id: json['id'],
      name: json['name'],
      price: parsedPrice,
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      categoryId: json['category_id'] ?? defaultCategoryId ?? 0,
      tenantId: json['tenant_id'] ?? defaultTenantId ?? 0,
    );
  }
}
