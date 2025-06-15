class OrderItem {
  final String productName;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['product_name'],
      quantity: json['quantity'],
      price: double.tryParse(json['price'] ?? '0') ?? 0,
      totalPrice: double.tryParse(json['total_price'] ?? '0') ?? 0,
    );
  }
}

class OrderNotification {
  final int orderId;
  final String customerName;
  final String porterName;
  final String orderStatus;
  final String tenantLocationName;
  final String createdAt;
  final List<OrderItem> items;

  OrderNotification({
    required this.orderId,
    required this.customerName,
    required this.porterName,
    required this.orderStatus,
    required this.tenantLocationName,
    required this.createdAt,
    required this.items,
  });

  factory OrderNotification.fromJson(Map<String, dynamic> json) {
    return OrderNotification(
      orderId: json['order_id'],
      customerName: json['customer_name'],
      porterName: json['porter_name'],
      orderStatus: json['order_status'],
      tenantLocationName: json['tenant_location_name'],
      createdAt: json['created_at'],
      items:
          (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList(),
    );
  }
}
