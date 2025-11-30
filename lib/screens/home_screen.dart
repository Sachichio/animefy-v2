import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import 'favorite_screen.dart';

enum SortOption { scoreDesc, titleAsc, titleDesc }

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const HomeScreen({
    Key? key,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> animeList = [];
  List<dynamic> airingAnimeList = [];
  List<dynamic> upcomingAnimeList = [];
  bool isLoading = true;

  SortOption? selectedSortPopular;
  SortOption? selectedSortAiring;
  SortOption? selectedSortUpcoming;

  @override
  void initState() {
    super.initState();
    getAnime();
    getAiringAnime();
    getUpcomingAnime();
  }

  List<dynamic> filterHentai(List<dynamic> data) {
    return data.where((anime) {
      if (anime['genres'] == null) return true;
      final genres = anime['genres'] as List<dynamic>;
      return !genres.any((g) => (g['name'] as String).toLowerCase() == 'hentai');
    }).toList();
  }

  Future<void> getAnime() async {
    try {
      final data = await ApiService.fetchTopAnime();
      final filtered = filterHentai(data);
      setState(() {
        animeList = filtered;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getAiringAnime() async {
    try {
      final data = await ApiService.fetchAiringAnime();
      final filtered = filterHentai(data);
      setState(() {
        airingAnimeList = filtered;
      });
    } catch (e) {
      print('Error fetching airing anime: $e');
    }
  }

  Future<void> getUpcomingAnime() async {
    try {
      final data = await ApiService.fetchUpcomingAnime();
      final filtered = filterHentai(data);
      setState(() {
        upcomingAnimeList = filtered;
      });
    } catch (e) {
      print('Error fetching upcoming anime: $e');
    }
  }

  void sortAnime(List<dynamic> list, SortOption option) {
    if (option == SortOption.scoreDesc) {
      list.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    } else if (option == SortOption.titleAsc) {
      list.sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
    } else if (option == SortOption.titleDesc) {
      list.sort((a, b) => (b['title'] ?? '').compareTo(a['title'] ?? ''));
    }
  }

  Widget buildSortMenu({
    required SortOption? selectedSort,
    required ValueChanged<SortOption> onSelected,
  }) {
    return PopupMenuButton<SortOption>(
      icon: Icon(Icons.filter_list, size: 24, color: Theme.of(context).colorScheme.primary),
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
        PopupMenuItem(value: SortOption.scoreDesc, child: Text('Sortir berdasarkan Skor')),
        PopupMenuItem(value: SortOption.titleAsc, child: Text('Sortir Judul A-Z')),
        PopupMenuItem(value: SortOption.titleDesc, child: Text('Sortir Judul Z-A')),
      ],
    );
  }

  Widget buildAnimeList(List<dynamic> list, int maxCount) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: list.length.clamp(0, maxCount),
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
      itemBuilder: (context, index) {
        final anime = list[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(anime: anime)),
              );
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: anime['images']['jpg']['image_url'] ?? '',
                width: 60,
                height: 90,
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.broken_image, size: 60, color: Colors.grey),
              ),
            ),
            title: Text(
              anime['title'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text("Score: ${anime['score'] ?? 'N/A'}"),
            ),
            trailing: Icon(Icons.chevron_right),
          ),
        );
      },
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
              Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              buildSortMenu(selectedSort: selectedSort, onSelected: onSortSelected),
            ],
          ),
        ),
        list.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text("Tidak ada data $title".toLowerCase())),
              )
            : buildAnimeList(list, maxCount),
      ],
    );
  }

  Widget _buildAppBarIcon({required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade400, Colors.indigo.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "Animefy",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
            ),
            centerTitle: true,
            actions: [
              _buildAppBarIcon(
                icon: Icons.favorite,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoriteScreen())),
              ),
              _buildAppBarIcon(
                icon: Icons.search,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen())),
              ),
              _buildAppBarIcon(icon: Icons.brightness_6, onTap: widget.toggleTheme),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSection(
                      "Popular Anime",
                      animeList,
                      selectedSortPopular,
                      (option) {
                        setState(() {
                          selectedSortPopular = option;
                          sortAnime(animeList, option);
                        });
                      },
                      5,
                    ),
                    buildSection(
                      "Ongoing Anime",
                      airingAnimeList,
                      selectedSortAiring,
                      (option) {
                        setState(() {
                          selectedSortAiring = option;
                          sortAnime(airingAnimeList, option);
                        });
                      },
                      12,
                    ),
                    buildSection(
                      "Upcoming Anime",
                      upcomingAnimeList,
                      selectedSortUpcoming,
                      (option) {
                        setState(() {
                          selectedSortUpcoming = option;
                          sortAnime(upcomingAnimeList, option);
                        });
                      },
                      10,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}