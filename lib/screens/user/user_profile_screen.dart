import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String username = "";
  String userId = "";
  String? avatarUrl;

  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController avatarCtrl = TextEditingController();

  bool isLoading = false;
  String livePreview = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username") ?? "User";
      avatarUrl = prefs.getString("avatarUrl");
      userId = prefs.getString("userId") ?? "";
      avatarCtrl.text = avatarUrl ?? "";
      livePreview = avatarUrl ?? "";
    });
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.isAbsolute && url.contains(".");
  }

  // ===============================
  // PREVIEW AVATAR
  // ===============================
  void _openPreviewDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: livePreview.isNotEmpty
                        ? Image.network(
                            livePreview,
                            height: 220,
                            width: 220,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 220,
                            width: 220,
                            alignment: Alignment.center,
                            color: Colors.grey.shade300,
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),
                  const Text("Preview Avatar",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text("Ketuk untuk menutup",
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===============================
  // RESET AVATAR
  // ===============================
  Future<void> _resetAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("avatarUrl");

    try {
      await http.put(
        Uri.parse("https://692c6a37c829d464006f81bc.mockapi.io/Users/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"avatarUrl": ""}),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal sinkron ke server")),
      );
    }

    setState(() {
      avatarUrl = null;
      avatarCtrl.clear();
      livePreview = "";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Avatar berhasil direset")),
    );
  }

  // ===============================
  // SAVE PROFILE
  // ===============================
  Future<void> _saveChanges() async {
    final newPassword = passwordCtrl.text.trim();
    final newAvatar = livePreview.trim();

    if (newAvatar.isEmpty && newPassword.isNotEmpty == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada perubahan")),
      );
      return;
    }

    setState(() => isLoading = true);

    final body = {
      if (newPassword.isNotEmpty) "password": newPassword,
      if (newAvatar.isNotEmpty) "avatarUrl": newAvatar,
    };

    try {
      final res = await http.put(
        Uri.parse("https://692c6a37c829d464006f81bc.mockapi.io/Users/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        if (newAvatar.isNotEmpty) {
          await prefs.setString("avatarUrl", newAvatar);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diperbarui")),
        );

        passwordCtrl.clear();
        setState(() => avatarUrl = newAvatar);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memperbarui profil")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  // ===============================
  // BUILD AVATAR
  // ===============================
  Widget _buildAvatar() {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundColor: Colors.teal,
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : "?",
          style: const TextStyle(fontSize: 40, color: Colors.white),
        ),
      );
    }

    return CircleAvatar(
      radius: 55,
      backgroundImage: NetworkImage(avatarUrl!),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile User",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _openPreviewDialog,
                    child: _buildAvatar(),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller: avatarCtrl,
                    onChanged: (value) {
                      setState(() {
                        livePreview =
                            _isValidUrl(value.trim()) ? value.trim() : "";
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "URL Foto Profil",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _resetAvatar,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  if (livePreview.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        livePreview,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  ],

                  const SizedBox(height: 20),

                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password Baru",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan Perubahan"),
                      onPressed: _saveChanges,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}