import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      final response = await http.get(
        Uri.parse('https://692c6a37c829d464006f81bc.mockapi.io/Users'),
      );

      if (response.statusCode == 200) {
        final List users = json.decode(response.body);
        Map<String, dynamic>? user;

        try {
          user = users.cast<Map<String, dynamic>>().firstWhere(
            (u) => u['username'] == username && u['password'] == password,
          );
        } catch (e) {
          user = null;
        }

        if (user != null) {
          // Simpan data user ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("username", user['username']);
          await prefs.setString("role", user['role'] ?? "user");
          await prefs.setBool("isLoggedIn", true);
          await prefs.setString("userId", user['id']);

          // WAJIB: simpan avatar ke shared preferences
          await prefs.setString("avatarUrl", user['avatarUrl'] ?? "");

          // LOGIN SUKSES — tidak perlu sinkronisasi favorit
          try {
            final String userId = user['id'];
            print("✔ Login berhasil. UserId: $userId");
          } catch (e) {
            print("⚠ Error setelah login: $e");
          }

          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Login berhasil sebagai ${user['username']} (${user['role']})"),
            ),
          );
        } else {
          setState(() {
            _errorMessage = "Username atau password salah!";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data user dari server!";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "Login Animefy",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                  onSubmitted: (_) => _login(),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  onSubmitted: (_) => _login(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text("Login"),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text("Belum punya akun? Daftar di sini"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}