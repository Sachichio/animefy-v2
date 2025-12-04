import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? userId;
  const SearchScreen({Key? key, this.userId}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;

  Future<void> searchAnime(String query) async {
    setState(() => isLoading = true);

    try {
      final data = await ApiService.searchAnime(query);

      final filtered = data.where((anime) {
        final genres = anime['genres'] as List<dynamic>? ?? [];
        return !genres.any((g) => (g['name'] as String).toLowerCase() == 'hentai');
      }).toList();

      setState(() {
        searchResults = filtered;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cari Anime")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Masukkan judul anime...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final query = _searchController.text.trim();
                    if (query.isNotEmpty) searchAnime(query);
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) searchAnime(value);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : searchResults.isEmpty
                      ? const Center(child: Text("Tidak ada hasil."))
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (_, index) {
                            final anime = searchResults[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FadeInImage.memoryNetwork(
                                  placeholder: kTransparentImage,
                                  image: anime['images']?['jpg']?['image_url'] ?? '',
                                  width: 50,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  imageErrorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                              title: Text(anime['title'] ?? 'Unknown'),
                              subtitle: Text("Score: ${anime['score'] ?? 'N/A'}"),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailScreen(
                                      anime: anime,
                                      userId: widget.userId,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}