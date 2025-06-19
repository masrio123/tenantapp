// file: lib/models/order.dart
class OrderNotification {
  final int id;
  final String customerName;
  final String orderStatus;
  final String? porterName;
  final DateTime createdAt;
  final List<OrderItem> items;

  OrderNotification({
    required this.id,
    required this.customerName,
    required this.orderStatus,
    this.porterName,
    required this.createdAt,
    required this.items,
  });

  factory OrderNotification.fromJson(Map<String, dynamic> json) {
    // FIX: Menambahkan pengecekan null untuk list 'items'
    var itemsList = json['items'] as List? ?? [];
    List<OrderItem> orderItems =
        itemsList.map((i) => OrderItem.fromJson(i)).toList();

    return OrderNotification(
      id: json['id'] ?? 0, // FIX: Memberi nilai default jika id null
      customerName: json['customer_name'] ?? 'No Name',
      orderStatus: json['order_status'] ?? 'Unknown',
      porterName: json['porter_name'],
      // FIX: Pengecekan null sebelum parsing tanggal
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      items: orderItems,
    );
  }
}

class OrderItem {
  final String productName;
  final int quantity;
  final int price;
  final String notes;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // FIX: Pengecekan null yang sangat aman untuk harga
    int parsedPrice = 0; // Default price adalah 0 jika data tidak valid
    if (json['price'] != null) {
      if (json['price'] is String) {
        parsedPrice = double.tryParse(json['price'])?.toInt() ?? 0;
      } else if (json['price'] is num) {
        parsedPrice = (json['price'] as num).toInt();
      }
    }

    return OrderItem(
      productName: json['product_name'] ?? 'Nama produk tidak tersedia',
      quantity: json['quantity'] ?? 0,
      notes: json['notes'],
      price: parsedPrice,
    );
  }
}
