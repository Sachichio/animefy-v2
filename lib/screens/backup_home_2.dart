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

  /// ===============================
  /// LOGIN STATUS
  /// ===============================
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
      userId = prefs.getString("userId"); // ambil userId saat login
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

  /// ===============================
  /// FILTER GENRE HENTAI
  /// ===============================
  List<dynamic> filterHentai(List<dynamic> data) {
    return data.where((anime) {
      final genres = anime['genres'] as List<dynamic>? ?? [];
      return !genres.any((g) => (g['name'] as String).toLowerCase() == 'hentai');
    }).toList();
  }

  /// ===============================
  /// FETCH DATA
  /// ===============================
  Future<void> getAnime() async {
    try {
      final data = await ApiService.fetchTopAnime();
      setState(() {
        animeList = filterHentai(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching top anime: $e');
    }
  }

  Future<void> getAiringAnime() async {
    try {
      final data = await ApiService.fetchAiringAnime();
      setState(() => airingAnimeList = filterHentai(data));
    } catch (e) {
      print('Error fetching airing anime: $e');
    }
  }

  Future<void> getUpcomingAnime() async {
    try {
      final data = await ApiService.fetchUpcomingAnime();
      setState(() => upcomingAnimeList = filterHentai(data));
    } catch (e) {
      print('Error fetching upcoming anime: $e');
    }
  }

  /// ===============================
  /// SORT
  /// ===============================
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

  /// ===============================
  /// APPBAR ICON
  /// ===============================
  Widget _buildAppBarIcon({required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  /// ===============================
  /// BUILD SECTION
  /// ===============================
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
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              PopupMenuButton<SortOption>(
                icon: Icon(Icons.filter_list, size: 24, color: Theme.of(context).colorScheme.primary),
                onSelected: onSortSelected,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: SortOption.scoreDesc, child: Text('Sortir berdasarkan Skor')),
                  PopupMenuItem(value: SortOption.titleAsc, child: Text('Sortir Judul A-Z')),
                  PopupMenuItem(value: SortOption.titleDesc, child: Text('Sortir Judul Z-A')),
                ],
              ),
            ],
          ),
        ),
        list.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text("Tidak ada data ${title.toLowerCase()}")),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length.clamp(0, maxCount),
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
                itemBuilder: (_, index) {
                  final anime = list[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          image: anime['images']?['jpg']?['image_url'] ?? '',
                          width: 60,
                          height: 90,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        ),
                      ),
                      title: Text(
                        anime['title'] ?? 'Unknown',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text("Score: ${anime['score'] ?? 'N/A'}"),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
      ],
    );
  }

  /// ===============================
  /// BUILD
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade400, Colors.indigo.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              "Animefy",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
            ),
            centerTitle: true,
            actions: [
              _buildAppBarIcon(
                icon: Icons.favorite,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FavoriteScreen(userId: userId)),
                ),
              ),
              _buildAppBarIcon(
                icon: Icons.search,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SearchScreen(userId: userId)),
                ),
              ),
              _buildAppBarIcon(icon: Icons.brightness_6, onTap: widget.toggleTheme),
              if (!isLoggedIn)
                _buildAppBarIcon(icon: Icons.login, onTap: _login)
              else
                _buildAppBarIcon(icon: Icons.logout, onTap: _logout),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSection("Popular Anime", animeList, selectedSortPopular, (option) {
                      setState(() {
                        selectedSortPopular = option;
                        sortAnime(animeList, option);
                      });
                    }, 5),
                    buildSection("Ongoing Anime", airingAnimeList, selectedSortAiring, (option) {
                      setState(() {
                        selectedSortAiring = option;
                        sortAnime(airingAnimeList, option);
                      });
                    }, 12),
                    buildSection("Upcoming Anime", upcomingAnimeList, selectedSortUpcoming, (option) {
                      setState(() {
                        selectedSortUpcoming = option;
                        sortAnime(upcomingAnimeList, option);
                      });
                    }, 10),
                  ],
                ),
              ),
            ),
    );
  }
}