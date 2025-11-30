import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final String baseUrl = "https://692c6a37c829d464006f81bc.mockapi.io/Users";

  Future<User?> login(String username, String password) async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List users = jsonDecode(response.body);
      for (var user in users) {
        if (user['username'] == username && user['password'] == password) {
          // Simpan session
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user['id']);
          await prefs.setString('username', user['username']);
          await prefs.setString('role', user['role']);
          return User.fromJson(user);
        }
      }
    }
    return null; // login gagal
  }

  Future<bool> register(String username, String password) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': 'user'
      }),
    );

    return response.statusCode == 201;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('userId');
  }
}