import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constant/constant.dart';
import '../models/tenant.dart';
import '../models/categories.dart';
import '../models/tenant_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tenant_id');
  }

  static Future<void> loadMenus({
    required List<String> categories,
    required Map<String, List<Map<String, dynamic>>> menus,
  }) async {
    try {
      final token = await getToken();
      final tenant_id = await getTenantId();

      print("tenant id $tenant_id");
      print('$baseURL/products?tenant_id=$tenant_id');

      final response = await http.get(
        Uri.parse('$baseURL/products?tenant_id=$tenant_id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        final dynamic dataRaw = jsonData['data'];

        if (dataRaw is List) {
          for (var category in dataRaw) {
            String categoryName = category['category_name'];
            categories.add(categoryName);

            List<Map<String, dynamic>> productList = [];
            for (var product in category['products']) {
              productList.add({
                'id': product['id'],
                'name': product['name'],
                'price': product['price'],
              });
            }
            menus[categoryName] = productList;
          }
        } else {
          throw Exception('Expected a List but got ${dataRaw.runtimeType}');
        }
      } else {
        throw Exception('Failed to fetch menu data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in loadMenus(): $e');
    }
  }

  static Future<Tenant> loadTenant() async {
    final token = await getToken();
    final tenant_id = await getTenantId();

    final response = await http.get(
      Uri.parse('$baseURL/tenants/$tenant_id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      return Tenant.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load tenant');
    }
  }

  static Future<void> deleteMenuById(int id) async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse('$baseURL/products/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus menu');
    }
  }

  static Future<bool> toggleTenantIsOpen(int tenantId) async {
    final token = await getToken();
    final tenant_id = await getTenantId();

    final url = Uri.parse('$baseURL/tenants/$tenant_id/toggle-is-open');
    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Gagal toggle isOpen. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Terjadi error saat toggle isOpen: $e');
      return false;
    }
  }

  static Future<void> createMenu({
    required String name,
    required double price,
    required String categoryId,
    required String tenantId,
    required bool isAvailable,
  }) async {
    final url = Uri.parse('$baseURL/products/store');
    final token = await getToken();
    final tenant_id = await getTenantId();

    print("category $categoryId");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'price': price,
        'category_id': categoryId,
        'tenant_id': tenant_id,
        'isAvailable': isAvailable,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('Menu berhasil disimpan: ${data['data']}');
    } else {
      print('Gagal menyimpan menu: ${response.body}');
    }
  }

  static Future<List<Category>> getCategories() async {
    final url = Uri.parse('$baseURL/categories');

    final token = await getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['success'] == true) {
        final List data = body['data'];
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat kategori: ${body['message']}');
      }
    } else {
      throw Exception('Gagal terhubung ke server: ${response.statusCode}');
    }
  }

  static Future<void> updateMenu({
    required int id,
    required String name,
    required double price,
    required bool isAvailable,
  }) async {
    final url = Uri.parse('$baseURL/products/$id');
    final token = await getToken();

    print("id $id, name $name, price $price, isAvailabel $isAvailable");

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'price': price,
          'isAvailable': isAvailable,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Menu berhasil diupdate: ${data['data']}');
      } else {
        print('Gagal mengupdate menu: ${response.body}');
      }
    } catch (e) {
      print('Error saat update menu: $e');
    }
  }

  static Future<void> toggleMenuAvailability({
    required int id,
    required bool isAvailable,
  }) async {
    final url = Uri.parse('$baseURL/products/$id/toggle-availability');

    final token = await getToken();

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'isAvailable': isAvailable}),
      );

      if (response.statusCode == 200) {
        print('Availability berhasil diubah.');
      } else {
        print('Gagal mengubah availability: ${response.body}');
      }
    } catch (e) {
      print('Error saat toggle availability: $e');
    }
  }

  static Future<bool> updateTenant({
    required int id,
    required String name,
    required int tenantLocationId,
    required bool isOpen,
  }) async {
    try {
      final token = await getToken();
      final tenant_id = await getTenantId();

      final response = await http.put(
        Uri.parse('$baseURL/tenants/$tenant_id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'tenant_location_id': tenantLocationId,
          'is_open': isOpen,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Gagal update tenant: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception saat update tenant: $e');
      return false;
    }
  }

  static Future<List<TenantLocation>> getTenantLocations() async {
    try {
      final token = await getToken();

      final response = await http.get(
        Uri.parse('$baseURL/tenant-locations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => TenantLocation.fromJson(e)).toList();
      } else {
        print("Gagal mengambil data lokasi: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception saat ambil lokasi tenant: $e");
      return [];
    }
  }
}
