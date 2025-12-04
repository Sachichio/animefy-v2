import 'package:flutter/material.dart';
import '../services/favorite_service.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  final String? userId; // userId diteruskan dari HomeScreen

  const FavoriteScreen({super.key, this.userId});

  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<dynamic> favorites = [];
  bool isLoading = true;

  final Set<int> _loadedIndexes = {}; // opsional, kalau mau optimasi list

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  /// ===============================
  /// LOAD FAVORITES
  /// ===============================
  Future<void> loadFavorites() async {
    setState(() {
      isLoading = true;
      _loadedIndexes.clear();
    });

    try {
      List<dynamic> data;

      if (widget.userId != null) {
        // Ambil dari server (MockAPI)
        data = await FavoriteService.getServerFavorites(widget.userId!);
      } else {
        // Ambil dari local storage
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

  /// ===============================
  /// GET IMAGE
  /// ===============================
  String getAnimeImage(Map<String, dynamic> anime) {
    return anime['image_url'] ??
        anime['imageUrl'] ??
        anime['images']?['jpg']?['image_url'] ??
        'https://via.placeholder.com/150';
  }

  /// ===============================
  /// BUILD
  /// ===============================
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
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                      title: Text(anime['title'] ?? 'No Title'),
                      subtitle: Text("Score: ${anime['score'] ?? '-'}"),
                      onTap: () async {
                        // Buka detail screen dan reload favorites setelah kembali
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(
                              anime: anime,
                              userId: widget.userId,
                            ),
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