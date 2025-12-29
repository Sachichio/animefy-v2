import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  List users = [];
  List filteredUsers = [];
  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => filterUsers(searchController.text);

  // ---------------------------
  // Helpers
  // ---------------------------
  bool _isValidUrl(String? input) {
    if (input == null || input.trim().isEmpty) return false;
    final uri = Uri.tryParse(input.trim());
    if (uri == null) return false;
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Color _avatarColorFor(String username) {
    final seed = username.isNotEmpty ? username.codeUnitAt(0) : 65;
    final colors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.teal,
      Colors.pink,
      Colors.orange,
      Colors.green,
      Colors.blueGrey,
      Colors.brown
    ];
    return colors[seed % colors.length].shade700;
  }

  Widget _avatarWidget({String? url, String? username, double radius = 20}) {
    if (_isValidUrl(url)) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, __) {
          // fallback to initial
        },
        child: null,
      );
    } else {
      final initial = (username ?? "").isNotEmpty ? (username![0].toUpperCase()) : "?";
      final color = _avatarColorFor(username ?? "");
      return CircleAvatar(
        radius: radius,
        backgroundColor: color,
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
          ),
        ),
      );
    }
  }

  // ---------------------------
  // FETCH USERS
  // ---------------------------
  Future<void> fetchUsers() async {
    setState(() => isLoading = true);

    try {
      final res = await http.get(
        Uri.parse("https://692c6a37c829d464006f81bc.mockapi.io/Users"),
      );

      if (res.statusCode == 200) {
        users = jsonDecode(res.body);
        users.sort((a, b) => a['username'].toString().compareTo(b['username']));
        filteredUsers = List.from(users);
      }
    } catch (e) {
      // ignore, but log
      debugPrint("fetchUsers error: $e");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // ---------------------------
  // SEARCH USER
  // ---------------------------
  void filterUsers(String query) {
    final q = query.toLowerCase();

    setState(() {
      filteredUsers = users.where((u) {
        return u['username'].toString().toLowerCase().contains(q);
      }).toList();
    });
  }

  // ---------------------------
  // CONFIRM DELETE
  // ---------------------------
  Future<bool> confirmDelete(String username) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: Text("Yakin ingin menghapus user '$username'?"),
        actions: [
          TextButton(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return res == true;
  }

  // ---------------------------
  // DELETE USER
  // ---------------------------
  Future<void> deleteUser(String id, String username) async {
    final ok = await confirmDelete(username);
    if (ok != true) return;

    try {
      final res = await http.delete(
        Uri.parse("https://692c6a37c829d464006f81bc.mockapi.io/Users/$id"),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("User berhasil dihapus")));
        await fetchUsers();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Gagal menghapus user")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan saat menghapus")));
    }
  }

  // ---------------------------
  // CREATE USER DIALOG (live preview + reset)
  // ---------------------------
  void openCreateUserDialog() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final avatarCtrl = TextEditingController();
    String role = "user";

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          void _localUpdate() {
            setStateDialog(() {});
          }

          // listener not applied to controller here — we use onChanged to update preview
          return AlertDialog(
            title: const Text("Tambah User Baru"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // live preview large avatar
                  GestureDetector(
                    onTap: () {
                      final url = avatarCtrl.text.trim();
                      showAvatarPreviewDialog(url: url, username: usernameCtrl.text.trim());
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.transparent,
                        child: _isValidUrl(avatarCtrl.text)
                            ? ClipOval(
                                child: Image.network(
                                  avatarCtrl.text,
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return _avatarWidget(username: usernameCtrl.text, radius: 42);
                                  },
                                ),
                              )
                            : _avatarWidget(username: usernameCtrl.text, radius: 42),
                      ),
                    ),
                  ),

                  TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(labelText: "Username"),
                    onChanged: (_) => _localUpdate(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: avatarCtrl,
                    decoration: InputDecoration(
                      labelText: "URL Avatar (opsional)",
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: "Reset avatar",
                            onPressed: () {
                              avatarCtrl.clear();
                              _localUpdate();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: "Preview besar",
                            onPressed: () {
                              showAvatarPreviewDialog(url: avatarCtrl.text.trim(), username: usernameCtrl.text.trim());
                            },
                          ),
                        ],
                      ),
                    ),
                    onChanged: (_) => _localUpdate(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(value: "user", child: Text("User")),
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                    ],
                    onChanged: (v) {
                      role = v ?? "user";
                      _localUpdate();
                    },
                    decoration: const InputDecoration(labelText: "Role"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                onPressed: () async {
                  final username = usernameCtrl.text.trim();
                  final password = passwordCtrl.text.trim();
                  final avatar = avatarCtrl.text.trim();

                  if (username.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Username dan password wajib diisi")));
                    return;
                  }

                  // unique username check (case-insensitive)
                  final exists = users.any((u) =>
                      u['username'].toString().toLowerCase() == username.toLowerCase());

                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Username sudah digunakan")));
                    return;
                  }

                  // optional avatar validation
                  if (avatar.isNotEmpty && !_isValidUrl(avatar)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("URL avatar tidak valid (http/https)")));
                    return;
                  }

                  final newUser = {
                    "username": username,
                    "password": password,
                    "role": role,
                    "avatarUrl": avatar.isEmpty ? null : avatar,
                  };

                  try {
                    final res = await http.post(
                      Uri.parse("https://692c6a37c829d464006f81bc.mockapi.io/Users"),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode(newUser),
                    );

                    if (!mounted) return;

                    if (res.statusCode == 201) {
                      Navigator.pop(context);
                      await fetchUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User baru ditambahkan")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Gagal menambahkan user")));
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Terjadi kesalahan saat menambahkan")));
                  }
                },
                child: const Text("Tambahkan"),
              ),
            ],
          );
        });
      },
    );
  }

  // ---------------------------
  // EDIT USER DIALOG (preview + reset)
  // ---------------------------
  void openEditUserDialog(Map user) {
    final passwordCtrl = TextEditingController(text: user['password'] ?? "");
    final avatarCtrl = TextEditingController(text: user['avatarUrl'] ?? "");
    String role = user['role'] ?? "user";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text("Edit User: ${user['username']}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => showAvatarPreviewDialog(url: avatarCtrl.text.trim(), username: user['username']),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.transparent,
                      child: _isValidUrl(avatarCtrl.text)
                          ? ClipOval(
                              child: Image.network(
                                avatarCtrl.text,
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarWidget(username: user['username'], radius: 42),
                              ),
                            )
                          : _avatarWidget(username: user['username'], radius: 42),
                    ),
                  ),
                ),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: "Password Baru (kosongkan kalau tidak diubah)"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: avatarCtrl,
                  decoration: InputDecoration(
                    labelText: "URL Foto Profil",
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: "Reset avatar",
                          onPressed: () {
                            avatarCtrl.clear();
                            setStateDialog(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          tooltip: "Preview besar",
                          onPressed: () => showAvatarPreviewDialog(url: avatarCtrl.text.trim(), username: user['username']),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: "user", child: Text("User")),
                    DropdownMenuItem(value: "admin", child: Text("Admin")),
                  ],
                  onChanged: (v) {
                    role = v ?? "user";
                    setStateDialog(() {});
                  },
                  decoration: const InputDecoration(labelText: "Role"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(child: const Text("Batal"), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              onPressed: () async {
                final newPassword = passwordCtrl.text.trim();
                final avatar = avatarCtrl.text.trim();

                // avatar validation if provided
                if (avatar.isNotEmpty && !_isValidUrl(avatar)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("URL avatar tidak valid (http/https)")));
                  return;
                }

                final body = {
                  if (newPassword.isNotEmpty) "password": newPassword,
                  "avatarUrl": avatar.isEmpty ? null : avatar,
                  "role": role,
                };

                try {
                  final res = await http.put(
                    Uri.parse("https://692c6a37c829d464006f81bc.mockapi.io/Users/${user['id']}"),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode(body),
                  );

                  if (!mounted) return;

                  if (res.statusCode == 200) {
                    final prefs = await SharedPreferences.getInstance();
                    String? currentId = prefs.getString("userId");

                    if (currentId == user['id'].toString()) {
                      // mengupdate avatar
                      if (body["avatarUrl"] == null) {
                        await prefs.remove("avatarUrl");  // HAPUS jika null
                      } else {
                        await prefs.setString("avatarUrl", body["avatarUrl"].toString());
                      }

                      // mengubah password
                      if (body["password"] != null) {
                        await prefs.setString("password", body["password"].toString());
                      }

                      // mengubah role
                      if (body["role"] != null) {
                        await prefs.setString("role", body["role"].toString());
                      }
                    }
                    Navigator.pop(context);
                    await fetchUsers();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data user diperbarui")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memperbarui user")));
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Terjadi kesalahan")));
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      }),
    );
  }

  // ---------------------------
  // BIG AVATAR PREVIEW DIALOG
  // ---------------------------
  void showAvatarPreviewDialog({required String url, required String username}) {
    showDialog(
      context: context,
      builder: (_) {
        final bool valid = _isValidUrl(url);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (valid)
                  ClipOval(
                    child: Image.network(
                      url,
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return _avatarWidget(username: username, radius: 80);
                      },
                    ),
                  )
                else
                  _avatarWidget(username: username, radius: 80),
                const SizedBox(height: 12),
                Text(
                  username.isNotEmpty ? username : "Preview",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola User",
        style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: openCreateUserDialog,
            tooltip: "Tambah user",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // search
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Cari username...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),

                // list
                Expanded(
                  child: filteredUsers.isEmpty
                      ? Center(child: Text("Tidak ada user", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: filteredUsers.length,
                          itemBuilder: (_, i) {
                            final user = filteredUsers[i];
                            final username = user['username'] ?? "Unknown";
                            final avatarUrl = user['avatarUrl'] ?? "";

                            return Card(
                              color: isDark ? Colors.grey[850] : Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                leading: GestureDetector(
                                  onTap: () => showAvatarPreviewDialog(url: avatarUrl, username: username),
                                  child: _isValidUrl(avatarUrl)
                                      ? CircleAvatar(
                                          radius: 26,
                                          backgroundImage: NetworkImage(avatarUrl),
                                          backgroundColor: Colors.transparent,
                                          onBackgroundImageError: (_, __) {},
                                        )
                                      : _avatarWidget(username: username, radius: 26),
                                ),
                                title: Text(username, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                                subtitle: Text("Role: ${user['role'] ?? 'user'}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => openEditUserDialog(user),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => deleteUser(user["id"], username),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
