class Product {
  final int id;
  final String name;
  final int price;
  final bool isAvailable;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    price: json['price'],
    isAvailable: json['is_available'] == 1,
  );
}