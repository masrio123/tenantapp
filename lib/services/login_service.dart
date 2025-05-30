import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseURL/login');

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      print("response success");
      final data = jsonDecode(response.body);

      if (data['user']['role'] != 'tenant') {
        return {
          'success': false,
          'message': 'akun Anda tidak memiliki role tenant',
        };
      }

      // Simpan token dan user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);
      await prefs.setString('token_type', data['token_type']);
      await prefs.setString('user_id', data['user']['id'].toString());
      await prefs.setString('user_name', data['user']['name']);
      await prefs.setString('user_email', data['user']['email']);
      await prefs.setString(
        'tenant_id',
        data['user']['tenant_id'].toString() ?? '',
      );
      await prefs.setString('role', data['user']['role']);

      return {'success': true, 'user': data['user']};
    } else {
      print('error login');
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Login gagal.'};
    }
  }
}
