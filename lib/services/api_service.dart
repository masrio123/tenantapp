import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constant/constant.dart';
import '../models/tenant.dart';

class ApiService {
  static Future<void> loadMenus({
    required List<String> categories,
    required Map<String, List<Map<String, dynamic>>> menus,
  }) async {
    try {
      final response = await http.get(Uri.parse('$baseURL/products/1'));

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
    final response = await http.get(Uri.parse('$baseURL/tenants/1'));

    if (response.statusCode == 200) {
      return Tenant.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load tenant');
    }
  }

  static Future<void> deleteMenuById(int id) async {
    final response = await http.delete(
      Uri.parse('$baseURL/products/$id/delete'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus menu');
    }
  }

  static Future<bool> toggleTenantIsOpen(int tenantId) async {
    final url = Uri.parse('$baseURL/tenants/$tenantId/toggle-is-open');

    try {
      final response = await http.patch(url);

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
}
