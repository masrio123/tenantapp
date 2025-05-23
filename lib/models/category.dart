import 'product.dart';

class ProductCategory {
  final int id;
  final String categoryName;
  final List<Product> products;

  ProductCategory({
    required this.id,
    required this.categoryName,
    required this.products,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      categoryName: json['category_name'],
      products: List<Product>.from(
        json['products'].map((item) => Product.fromJson(item)),
      ),
    );
  }
}