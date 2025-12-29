import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import 'favorite_screen.dart';

enum SortOption { scoreDesc, titleAsc, titleDesc }

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const HomeScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> animeList = [];
  List<dynamic> airingAnimeList = [];
  List<dynamic> upcomingAnimeList = [];
  bool isLoading = true;
  bool isLoggedIn = false;
  String? userId;
  String? userRole;


  SortOption? selectedSortPopular;
  SortOption? selectedSortAiring;
  SortOption? selectedSortUpcoming;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    getAnime();
    getAiringAnime();
    getUpcomingAnime();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
      userId = prefs.getString("userId");
      userRole = prefs.getString("role") ?? "user"; // AMBIL ROLE
    });
  }

  Future<void> _login() async {
    await Navigator.pushNamed(context, "/login");
    await _checkLoginStatus();

    if (isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString("username") ?? "User";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selamat datang! $username")),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      isLoggedIn = false;
      userId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logout berhasil!")),
    );
  }

  List<dynamic> filterHentai(List<dynamic> data) {
    return data.where((anime) {
      final genres = anime['genres'] as List<dynamic>? ?? [];
      return !genres.any((g) => (g['name'] as String).toLowerCase() == 'hentai');
    }).toList();
  }

  Future<void> getAnime() async {
    try {
      final data = await ApiService.fetchTopAnime();
      setState(() {
        animeList = filterHentai(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> getAiringAnime() async {
    try {
      final data = await ApiService.fetchAiringAnime();
      setState(() => airingAnimeList = filterHentai(data));
    } catch (e) {}
  }

  Future<void> getUpcomingAnime() async {
    try {
      final data = await ApiService.fetchUpcomingAnime();
      setState(() => upcomingAnimeList = filterHentai(data));
    } catch (e) {}
  }

  void sortAnime(List<dynamic> list, SortOption option) {
    switch (option) {
      case SortOption.scoreDesc:
        list.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
        break;
      case SortOption.titleAsc:
        list.sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
        break;
      case SortOption.titleDesc:
        list.sort((a, b) => (b['title'] ?? '').compareTo(a['title'] ?? ''));
        break;
    }
  }

  Widget _buildAppBarIcon({required IconData icon, required VoidCallback onTap}) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isMobile ? 22 : 26,
          ),
        ),
      ),
    );
  }

  Widget buildSection(
    String title,
    List<dynamic> list,
    SortOption? selectedSort,
    ValueChanged<SortOption> onSortSelected,
    int maxCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              PopupMenuButton<SortOption>(
                icon: const Icon(Icons.filter_list),
                onSelected: onSortSelected,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: SortOption.scoreDesc,
                      child: Text('Sortir berdasarkan Skor')),
                  PopupMenuItem(
                      value: SortOption.titleAsc,
                      child: Text('Sortir Judul A-Z')),
                  PopupMenuItem(
                      value: SortOption.titleDesc,
                      child: Text('Sortir Judul Z-A')),
                ],
              ),
            ],
          ),
        ),
        list.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text("Tidak ada data")),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length.clamp(0, maxCount),
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade300),
                itemBuilder: (_, index) {
                  final anime = list[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(
                              anime: anime,
                              userId: isLoggedIn ? userId : null,
                            ),
                          ),
                        );
                      },
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image:
                              anime['images']?['jpg']?['image_url'] ?? '',
                          width: 60,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(anime['title'] ?? 'Unknown'),
                      subtitle:
                          Text("Score: ${anime['score'] ?? 'N/A'}"),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      // ================================
      // HAMBURGER MENU FIX
      // ================================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple.shade400),
              child: const Center(
                child: Text(
                  "Animefy Menu",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // =======================
            // TOMBOL DASHBOARD ADMIN
            // =======================
            if (isLoggedIn && userRole == "admin")
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text("Dashboard Admin"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, "/admin/dashboard");
                },
              ),

            // =======================
            // TOMBOL DASHBOARD USER
            // =======================
            if (isLoggedIn && userRole == "user")
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text("Dashboard User"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, "/user/dashboard");
                },
              ),

            // =======================
            // MENU GENRE
            // =======================
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text("Genre"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/anime/genre");
              },
            ),

            // =======================
            // MENU SEASON
            // =======================
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Season"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/anime/season");
              },
            ),

            // =======================
            // MENU STUDIO
            // =======================
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text("Studio"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/anime/studio");
              },
            ),

            // =======================
            // MENU POPULAR
            // =======================
            ListTile(
              leading: const Icon(Icons.local_fire_department),
              title: const Text("Popular Anime"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/anime/popular");
              },
            ),

            // =======================
            // MENU ONGOING
            // =======================
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: const Text("Ongoing Anime"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/anime/ongoing");
              },
            ),

            // =======================
            // MENU COMPLETED
            // =======================
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text("Completed Anime"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/anime/completed");
              },
            ),

            // =======================
            // MENU UPCOMING
            // =======================
            ListTile(
              leading: const Icon(Icons.new_releases),
              title: const Text("Upcoming Anime"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/anime/upcoming");
              },
            ),
          ],
        ),
      ),

      // ================================
      // APP BAR: title dihapus
      // ================================
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade400,
                Colors.indigo.shade600
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: true,
            iconTheme: const IconThemeData(color: Colors.white),

            title: const Text(
              "Animefy",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            centerTitle: false, // Judul jadi di kiri dekat hamburger

            actions: [
              _buildAppBarIcon(
                icon: Icons.favorite,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FavoriteScreen(userId: userId)),
                ),
              ),
              _buildAppBarIcon(
                icon: Icons.search,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SearchScreen(userId: userId)),
                ),
              ),
              _buildAppBarIcon(
                  icon: Icons.brightness_6, onTap: widget.toggleTheme),
              if (!isLoggedIn)
                _buildAppBarIcon(icon: Icons.login, onTap: _login)
              else
                _buildAppBarIcon(icon: Icons.logout, onTap: _logout),
              SizedBox(width: isMobile ? 4 : 12),
            ],
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSection("Popular Anime", animeList,
                        selectedSortPopular, (opt) {
                      setState(() {
                        selectedSortPopular = opt;
                        sortAnime(animeList, opt);
                      });
                    }, 5),

                    buildSection("Ongoing Anime", airingAnimeList,
                        selectedSortAiring, (opt) {
                      setState(() {
                        selectedSortAiring = opt;
                        sortAnime(airingAnimeList, opt);
                      });
                    }, 12),

                    buildSection("Upcoming Anime", upcomingAnimeList,
                        selectedSortUpcoming, (opt) {
                      setState(() {
                        selectedSortUpcoming = opt;
                        sortAnime(upcomingAnimeList, opt);
                      });
                    }, 10),
                  ],
                ),
              ),
            ),
    );
  }
}