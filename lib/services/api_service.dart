import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/constant.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/tenant.dart';
import '../models/tenant_location.dart';
import '../models/order.dart';

class ApiService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> _getTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tenant_id');
  }

  static Future<List<Category>> getCategories() async {
    final token = await _getToken();
    final url = Uri.parse('$baseURL/categories');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['success'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((json) => Category.fromJson(json))
            .toList();
      }
    }
    throw Exception('Gagal memuat kategori: ${response.statusCode}');
  }

  static Future<List<Product>> getProductsByTenantId(int tenantId) async {
    final token = await _getToken();
    // FIX: Menggunakan URL yang benar sesuai dengan routes/api.php
    final url = Uri.parse('$baseURL/products?tenant_id=$tenantId');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['success'] == true && body['data'] is List) {
        final List categoriesJson = body['data'];
        final List<Product> allProducts = [];

        for (var categoryData in categoriesJson) {
          if (categoryData['products'] is! List) continue;
          final int categoryId = categoryData['id'];
          final List productsJson = categoryData['products'];
          for (var productData in productsJson) {
            allProducts.add(
              Product.fromJson(
                productData,
                defaultCategoryId: categoryId,
                defaultTenantId: tenantId,
              ),
            );
          }
        }
        return allProducts;
      }
      throw Exception('Format data produk tidak valid.');
    }
    throw Exception('Gagal memuat produk. Status: ${response.statusCode}');
  }

  static Future<void> createMenu({
    required String name,
    required int price,
    required int categoryId,
    required int tenantId,
    required bool isAvailable,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('$baseURL/products/store');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'price': price,
        'category_id': categoryId,
        'tenant_id': tenantId,
        'isAvailable': isAvailable,
      }),
    );
    if (response.statusCode != 201)
      throw Exception('Gagal membuat menu: ${response.body}');
  }

  // FIX: Mengubah metode dari POST menjadi PUT untuk mengatasi error 405 Method Not Allowed.
  static Future<void> updateMenu({
    required int id,
    required String name,
    required int price,
    required bool isAvailable,
  }) async {
    final token = await _getToken();
    // FIX: Menggunakan URL yang benar sesuai dengan routes/api.php
    final url = Uri.parse('$baseURL/products/$id');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'price': price,
        'isAvailable': isAvailable,
      }),
    );
    if (response.statusCode != 200)
      throw Exception('Gagal memperbarui menu: ${response.body}');
  }

  static Future<void> deleteMenuById(int id) async {
    final token = await _getToken();
    // FIX: Menggunakan URL yang benar sesuai dengan routes/api.php
    final url = Uri.parse('$baseURL/products/$id');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode != 200 && response.statusCode != 204)
      throw Exception('Gagal menghapus menu: ${response.body}');
  }

  static Future<Tenant> loadTenant() async {
    final token = await _getToken();
    final tenantId = await _getTenantId();
    if (tenantId == null) throw Exception('ID Tenant tidak ditemukan.');
    final response = await http.get(
      Uri.parse('$baseURL/tenants/$tenantId'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200)
      return Tenant.fromJson(jsonDecode(response.body));
    throw Exception('Gagal memuat data tenant: ${response.statusCode}');
  }

  static Future<List<TenantLocation>> getTenantLocations() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseURL/tenant-locations'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200)
      return (jsonDecode(response.body) as List)
          .map((e) => TenantLocation.fromJson(e))
          .toList();
    throw Exception("Gagal mengambil data lokasi: ${response.body}");
  }

  static Future<Tenant> updateTenant({
    required int id,
    required String name,
    required int tenantLocationId,
    required bool isOpen,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseURL/tenants/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'tenant_location_id': tenantLocationId,
        'is_open': isOpen,
      }),
    );
    if (response.statusCode == 200)
      return Tenant.fromJson(jsonDecode(response.body));
    throw Exception('Gagal memperbarui profil tenant: ${response.body}');
  }

  static Future<void> toggleTenantIsOpen(int tenantId) async {
    final token = await _getToken();
    final url = Uri.parse('$baseURL/tenants/$tenantId/toggle-is-open');
    final response = await http.patch(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode != 200)
      throw Exception('Gagal mengubah status tenant: ${response.body}');
  }

  static Future<List<OrderNotification>> fetchOrderNotifications() async {
    final token = await _getToken();
    final tenantId = await _getTenantId();
    if (tenantId == null) return [];
    final url = Uri.parse('$baseURL/tenants/$tenantId/order-notifications');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data'] is List)
          return (body['data'] as List)
              .map((json) => OrderNotification.fromJson(json))
              .toList();
        return [];
      }
      debugPrint('Gagal mengambil notifikasi: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error saat fetch notifikasi: $e');
      return [];
    }
  }
}
