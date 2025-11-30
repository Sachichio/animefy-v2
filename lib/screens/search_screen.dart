import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> searchResults = [];
  TextEditingController _searchController = TextEditingController();
  bool isLoading = false;

  Future<void> searchAnime(String query) async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.searchAnime(query);

      // Fungsi filter untuk membatasi genre 18+
      final filtered = data.where((anime) {
        if (anime['genres'] == null) return true;
        final genres = anime['genres'] as List<dynamic>;
        return !genres.any((g) => (g['name'] as String).toLowerCase() == 'hentai');
      }).toList();

      setState(() {
        searchResults = filtered;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
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
      appBar: AppBar(
        title: Text("Cari Anime"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Kolom pencarian
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Masukkan judul anime...",
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    final query = _searchController.text.trim();
                    if (query.isNotEmpty) {
                      searchAnime(query);
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  searchAnime(value);
                }
              },
            ),
            SizedBox(height: 20),

            // Hasil pencarian
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (searchResults.isEmpty)
              Expanded(child: Center(child: Text("Tidak ada hasil.")))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final anime = searchResults[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: anime['images']['jpg']['image_url'],
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.broken_image),
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
              ),
          ],
        ),
      ),
    );
  }
}