import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
      // 1. Fetch data user dari MockAPI
      final response = await http.get(
        Uri.parse('https://692c6a37c829d464006f81bc.mockapi.io/Users'),
      );

      if (response.statusCode == 200) {
        final List users = json.decode(response.body);

        // 2. Cari user yang cocok
        final user = users.firstWhere(
          (u) => u['username'] == username && u['password'] == password,
          orElse: () => null,
        );

        if (user != null) {
          // 3. Simpan info user ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("username", user['username']);
          await prefs.setString("role", user['role']);
          await prefs.setBool("isLoggedIn", true);

          if (!mounted) return;

          // 4. Navigasi ke HomeScreen
          Navigator.pushReplacementNamed(context, '/home');

          // 5. Tampilkan Snackbar sukses login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login berhasil sebagai ${user['username']} (${user['role']})")),
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
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}