import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl =
      'https://9b58-114-10-47-78.ngrok-free.app/api/products';

  static Future<void> loadMenus({
    required List<String> categories,
    required Map<String, List<Map<String, dynamic>>> menus,
  }) async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      print('📤 Requesting: $apiUrl');
      print('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Debugging type of 'data'
        print('📦 Response "data" type: ${jsonData["data"].runtimeType}');

        final dynamic dataRaw = jsonData['data'];

        if (dataRaw is List) {
          for (var category in dataRaw) {
            String categoryName = category['category_name'];
            categories.add(categoryName);

            List<Map<String, dynamic>> productList = [];
            for (var product in category['products']) {
              productList.add({
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
      print('❌ Error in loadMenus(): $e');
    }
  }
}