import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String username = "";
  String? avatarUrl;

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
    });
  }

  // CARD DASHBOARD — sama seperti admin
  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    const darkPurple = Color(0xFF5A4AE3);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1F1F23) : const Color(0xFFF5F5F7),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? darkPurple : theme.colorScheme.primary,

        iconTheme: IconThemeData(
          color: isDark ? Colors.white : theme.colorScheme.onPrimary,
        ),

        title: Text(
          "Dashboard User",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : theme.colorScheme.onPrimary,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// HEADER USER
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? darkPurple : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person,
                            size: 40, color: Colors.grey)
                        : null,
                  ),

                  const SizedBox(width: 18),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "User",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : Colors.white.withOpacity(.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// LOGOUT
                  IconButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Logout berhasil!"),
                          duration: Duration(seconds: 2),
                        ),
                      );

                      await Future.delayed(const Duration(milliseconds: 800));

                      if (!mounted) return;

                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        "/home",
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// GRID MENU USER
            GridView.count(
              crossAxisCount: isMobile ? 2 : 3,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDashboardCard(
                  icon: Icons.comment,
                  title: "Komentar Saya",
                  onTap: () =>
                      Navigator.pushNamed(context, "/user/comments"),
                ),
                _buildDashboardCard(
                  icon: Icons.person,
                  title: "Profile Saya",
                  onTap: () => Navigator.pushNamed(context, "/user/profile"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}