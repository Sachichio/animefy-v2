import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/favorite_service.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<dynamic> favorites = [];
  bool isLoading = true;
  String? userId;

  final Set<int> _loadedIndexes = {};

  @override
  void initState() {
    super.initState();
    loadUserAndFavorites();
  }

  Future<void> loadUserAndFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');

    await loadFavorites();
  }

  Future<void> loadFavorites() async {
    setState(() {
      isLoading = true;
      _loadedIndexes.clear();
    });

    try {
      List<dynamic> data;

      if (userId != null) {
        data = await FavoriteService.getServerFavorites(userId!);
      } else {
        data = await FavoriteService.getFavoritesLocal();
      }

      if (!mounted) return;
      setState(() {
        favorites = data;
        isLoading = false;
      });

    } catch (e) {
      print("Error load favorites: $e");
      if (!mounted) return;
      setState(() {
        favorites = [];
        isLoading = false;
      });
    }
  }

  String getAnimeImage(Map<String, dynamic> anime) {
    return anime['image_url'] ??
        anime['imageUrl'] ??
        anime['images']?['jpg']?['image_url'] ??
        'https://via.placeholder.com/150';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Anime Favorit")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? const Center(child: Text("Belum ada anime favorit."))
              : ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final anime = favorites[index];
                    final imageUrl = getAnimeImage(anime);

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 50);
                          },
                        ),
                      ),
                      title: Text(anime['title'] ?? 'No Title'),
                      subtitle: Text(
                        "Score: ${anime['score'] ?? '-'}",
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetailScreen(anime: anime, userId: userId),
                          ),
                        );
                        await loadFavorites();
                      },
                    );
                  },
                ),
    );
  }
}