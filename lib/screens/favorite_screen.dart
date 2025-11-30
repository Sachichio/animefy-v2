import 'package:flutter/material.dart';
import '../services/favorite_service.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<dynamic> favorites = [];
  bool isLoading = true;

  // Tracking index gambar yang sudah selesai load, untuk animasi fade-in
  final Set<int> _loadedIndexes = {};

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final data = await FavoriteService.getFavorites();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Anime Favorit")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? Center(child: Text("Belum ada anime favorit."))
              : ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final anime = favorites[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedOpacity(
                          opacity: _loadedIndexes.contains(index) ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          child: Image.network(
                            anime['images']['jpg']['image_url'],
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                // Gambar sudah selesai load, tambahkan index untuk fade-in
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
                                // Sementara loading, tampilkan progress indicator kecil
                                return SizedBox(
                                  width: 50,
                                  height: 70,
                                  child: Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              }
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.broken_image, size: 50);
                            },
                          ),
                        ),
                      ),
                      title: Text(anime['title']),
                      subtitle: Text("Score: ${anime['score'] ?? 'N/A'}"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(anime: anime),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}