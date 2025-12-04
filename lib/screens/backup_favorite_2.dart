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

  // Tracking index gambar agar animasi berjalan ulang setelah refresh
  final Set<int> _loadedIndexes = {};

  @override
  void initState() {
    super.initState();
    loadUserAndFavorites();
  }

  /// Ambil userId dari SharedPreferences dan load favorites
  Future<void> loadUserAndFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId'); // null jika belum login
    print("Current userId: $userId");
    await loadFavorites();
  }

  /// Load favorites dari server atau local
  Future<void> loadFavorites() async {
    setState(() {
      isLoading = true;
      _loadedIndexes.clear(); // Reset animasi gambar
    });

    try {
      List<dynamic> data;
      if (userId != null) {
        // User login → ambil dari server
        data = await FavoriteService.getServerFavorites(userId!);
        print("Loaded ${data.length} favorites from server.");
      } else {
        // Guest → ambil dari local
        data = await FavoriteService.getFavoritesLocal();
        print("Loaded ${data.length} favorites from local.");
      }

      if (!mounted) return;
      setState(() {
        favorites = data;
        isLoading = false;
      });
    } catch (e, stack) {
      print("Error load favorites: $e");
      print(stack);
      if (!mounted) return;
      setState(() {
        favorites = [];
        isLoading = false;
      });
    }
  }

  /// Helper untuk ambil gambar anime
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
                        child: AnimatedOpacity(
                          opacity: _loadedIndexes.contains(index) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          child: Image.network(
                            imageUrl,
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                if (!_loadedIndexes.contains(index)) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() {
                                        _loadedIndexes.add(index);
                                      });
                                    }
                                  });
                                }
                                return child;
                              } else {
                                return const SizedBox(
                                  width: 50,
                                  height: 70,
                                  child: Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              }
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 50);
                            },
                          ),
                        ),
                      ),
                      title: Text(anime['title'] ?? 'N/A'),
                      subtitle: Text("Score: ${anime['score'] ?? 'N/A'}"),
                      onTap: () async {
                        // Masuk ke detail
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(anime: anime, userId: userId),
                          ),
                        );
                        // Reload favorites setelah kembali
                        await loadFavorites();
                      },
                    );
                  },
                ),
    );
  }
}