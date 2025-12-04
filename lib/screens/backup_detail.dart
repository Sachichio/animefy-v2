import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/favorite_service.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> anime;
  final String? userId;

  const DetailScreen({required this.anime, this.userId, super.key});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isFavorite = false;
  bool showIndonesian = false;
  String translatedSynopsis = '';
  bool isTranslating = false;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    checkFavorite();
  }

  /// ===================== FAVORITE =====================
  Future<void> checkFavorite() async {
    try {
      final fav = await FavoriteService.checkFavorite(
        widget.anime,
        userId: widget.userId,
      );
      if (mounted) setState(() => isFavorite = fav);
    } catch (e) {
      if (mounted) setState(() => isFavorite = false);
      print('Error checking favorite: $e');
    }
  }

  Future<void> toggleFavorite() async {
    try {
      final fav = await FavoriteService.toggleFavorite(
        widget.anime,
        userId: widget.userId,
      );
      if (mounted) setState(() => isFavorite = fav);
    } catch (e) {
      print('Error toggle favorite: $e');
    }
  }

  /// ===================== TRANSLATE =====================
  Future<String> translateText(String text, String targetLang) async {
    try {
      final encodedText = Uri.encodeComponent(text);
      final url = Uri.parse(
          'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$targetLang&dt=t&q=$encodedText');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        String result = '';
        for (var item in jsonResponse[0]) {
          if (item[0] != null) result += item[0];
        }
        return result;
      }
      return 'Terjemahan tidak tersedia.';
    } catch (_) {
      return 'Terjemahan tidak tersedia.';
    }
  }

  void toggleLanguage() async {
    final englishSynopsis = widget.anime['synopsis'] ?? 'Tidak tersedia sinopsis.';
    if (!showIndonesian) {
      setState(() => isTranslating = true);
      final res = await translateText(englishSynopsis, 'id');
      if (mounted) {
        setState(() {
          translatedSynopsis = res;
          showIndonesian = true;
          isTranslating = false;
        });
      }
    } else {
      if (mounted) setState(() => showIndonesian = false);
    }
  }

  /// ===================== HELPERS =====================
  Color chipBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.deepPurple.shade50;
  }

  Widget _infoChip(String label, String? value) {
    final displayValue = (value == null || value.toString().trim().isEmpty) ? 'N/A' : value;
    return Material(
      color: chipBackgroundColor(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text("$label: $displayValue", style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _customChip(String text) {
    final display = (text.trim().isEmpty) ? 'N/A' : text;
    return Material(
      color: chipBackgroundColor(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(display, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _infoBox(String? value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: chipBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(value == null || value.toString().trim().isEmpty ? 'N/A' : value,
          style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _studioOrGenreList(List<dynamic>? items) {
    final itemList = items ?? [];
    if (itemList.isEmpty) {
      // tampilkan chip N/A agar konsisten
      return SizedBox(height: 32, child: _customChip('N/A'));
    }

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: itemList.map<Widget>((item) {
          // ambil nama dan bersihkan trailing ":" atau whitespace
          String name = (item?['name']?.toString() ?? '').trim();
          // hapus trailing ":" jika ada (termasuk spasi)
          name = name.replaceAll(RegExp(r'[:\s]+$'), '');
          if (name.isEmpty) name = 'N/A';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _customChip(name),
          );
        }).toList(),
      ),
    );
  }

  /// ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    final anime = widget.anime;
    final englishSynopsis = anime['synopsis'] ?? 'Tidak tersedia sinopsis.';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDarkMode ? Colors.white : Colors.black87;
    final inactiveColor = isDarkMode ? Colors.white54 : Colors.black38;

    final imageUrl = anime['images']?['jpg']?['image_url'] ??
        anime['image_url'] ??
        anime['imageUrl'] ??
        'https://via.placeholder.com/150';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: Colors.deepPurple,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  anime['title'] ?? 'Unknown',
                  style: TextStyle(
                    shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  softWrap: true,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (_, __, ___) => Container(color: Colors.black54),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedOpacity(
                          opacity: _imageLoaded ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 600),
                          child: Image.network(
                            imageUrl,
                            height: 180,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loading) {
                              if (loading == null) {
                                // image sudah selesai load
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) setState(() => _imageLoaded = true);
                                });
                                return child;
                              }
                              return const SizedBox(
                                height: 180,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.broken_image, size: 80),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.white),
                onPressed: toggleFavorite,
              ),
              Row(
                children: [
                  Text("EN", style: TextStyle(color: !showIndonesian ? activeColor : inactiveColor)),
                  Switch(
                    value: showIndonesian,
                    activeColor: activeColor,
                    onChanged: (v) {
                      if (!isTranslating) toggleLanguage();
                    },
                  ),
                  Text("ID", style: TextStyle(color: showIndonesian ? activeColor : inactiveColor)),
                ],
              ),
            ],
          ),

          // ===================== INFO SECTION =====================
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _infoChip('Type', anime['type']?.toString()),
                            _infoChip('Episode', anime['episodes']?.toString()),
                            _infoChip('Status', anime['status']?.toString()),
                            _infoChip('Score', anime['score']?.toString()),
                            _infoChip('Season', anime['season']?.toString()),
                            _infoChip('Duration', anime['duration']?.toString()),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Text('English', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _infoBox(anime['title_english']?.toString()),
                        const SizedBox(height: 20),
                        Text('Japanese', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _infoBox(anime['title_japanese']?.toString()),
                        const SizedBox(height: 20),
                        Text('Studio', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _studioOrGenreList(anime['studios'] as List<dynamic>?),
                        const SizedBox(height: 20),
                        Text('Genre', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _studioOrGenreList(anime['genres'] as List<dynamic>?),
                        const SizedBox(height: 55),
                        Text('Sinopsis', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        isTranslating ? const Center(child: CircularProgressIndicator()) : Text(
                          showIndonesian ? translatedSynopsis : englishSynopsis,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}