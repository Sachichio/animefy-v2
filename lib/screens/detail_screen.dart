import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/favorite_service.dart';

class DetailScreen extends StatefulWidget {
  final dynamic anime;
  DetailScreen({required this.anime});

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

  Future<void> checkFavorite() async {
    final fav = await FavoriteService.isFavorite(widget.anime['mal_id']);
    setState(() {
      isFavorite = fav;
    });
  }

  Future<void> toggleFavorite() async {
    if (isFavorite) {
      await FavoriteService.removeFavorite(widget.anime['mal_id']);
    } else {
      await FavoriteService.addFavorite(widget.anime);
    }
    checkFavorite();
  }

  Future<String> translateText(String text, String targetLang) async {
    try {
      final encodedText = Uri.encodeComponent(text);
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$targetLang&dt=t&q=$encodedText',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> translations = jsonResponse[0];
        String result = '';
        for (var item in translations) {
          if (item[0] != null) {
            result += item[0];
          }
        }
        return result;
      } else {
        return 'Terjemahan tidak tersedia.';
      }
    } catch (e) {
      return 'Terjemahan tidak tersedia.';
    }
  }

  void toggleLanguage() async {
    final englishSynopsis = widget.anime['synopsis'] ?? 'Tidak tersedia sinopsis.';
    if (!showIndonesian) {
      setState(() {
        isTranslating = true;
      });
      final result = await translateText(englishSynopsis, 'id');
      setState(() {
        translatedSynopsis = result;
        showIndonesian = true;
        isTranslating = false;
      });
    } else {
      setState(() {
        showIndonesian = false;
      });
    }
  }

  Color chipBackgroundColor(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white24 : Colors.deepPurple.shade50;
  }

  @override
  Widget build(BuildContext context) {
    final anime = widget.anime;
    final englishSynopsis = anime['synopsis'] ?? 'Tidak tersedia sinopsis.';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDarkMode ? Colors.white : Colors.black87;
    final inactiveColor = isDarkMode ? Colors.white54 : Colors.black38;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: Colors.deepPurple,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
              title: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.5)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 100,
                  ),
                  child: Text(
                    anime['title'],
                    style: TextStyle(
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black54,
                          offset: Offset(1, 1),
                        )
                      ],
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    anime['images']['jpg']['image_url'],
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return Container(color: Colors.black54);
                      }
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.black54);
                    },
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
                          duration: Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          child: Image.network(
                            anime['images']['jpg']['image_url'],
                            fit: BoxFit.contain,
                            height: 180,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                if (!_imageLoaded) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() {
                                        _imageLoaded = true;
                                      });
                                    }
                                  });
                                }
                                return child;
                              } else {
                                return SizedBox(
                                  height: 180,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: Colors.grey.shade300,
                                child: Icon(Icons.broken_image, size: 80),
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
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : Colors.white,
                ),
                onPressed: toggleFavorite,
                tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Text("EN", style: TextStyle(color: showIndonesian ? inactiveColor : activeColor)),
                    Switch(
                      value: showIndonesian,
                      activeColor: activeColor,
                      inactiveThumbColor: inactiveColor,
                      inactiveTrackColor: inactiveColor.withOpacity(0.4),
                      onChanged: (val) {
                        if (!isTranslating) toggleLanguage();
                      },
                    ),
                    Text("ID", style: TextStyle(color: showIndonesian ? activeColor : inactiveColor)),
                  ],
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).cardColor,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _infoChip(context, 'Type', anime['type'] ?? 'N/A'),
                                _infoChip(context, 'Episode', anime['episodes']?.toString() ?? 'N/A'),
                                _infoChip(context, 'Status', anime['status'] ?? 'N/A'),
                                _infoChip(context, 'Score', anime['score']?.toString() ?? 'N/A'),
                                _infoChip(context, 'Season', anime['season'] ?? 'N/A'),
                                _infoChip(context, 'Duration', anime['duration'] ?? 'N/A'),
                              ],
                            ),
                            SizedBox(height: 35),
                            Text('English', style: Theme.of(context).textTheme.titleMedium),
                            SizedBox(height: 8),
                            _infoBox(context, anime['title_english']),
                            SizedBox(height: 20),
                            Text('Japanese', style: Theme.of(context).textTheme.titleMedium),
                            SizedBox(height: 8),
                            _infoBox(context, anime['title_japanese']),
                            SizedBox(height: 20),
                            Text('Studio', style: Theme.of(context).textTheme.titleMedium),
                            SizedBox(height: 8),
                            _studioOrGenreList(anime['studios']),
                            SizedBox(height: 20),
                            Text('Genre', style: Theme.of(context).textTheme.titleMedium),
                            SizedBox(height: 8),
                            _studioOrGenreList(anime['genres']),
                            SizedBox(height: 55),
                            Text(
                              'Sinopsis',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12),
                            isTranslating
                                ? Center(child: CircularProgressIndicator())
                                : Text(
                                    showIndonesian ? translatedSynopsis : englishSynopsis,
                                    textAlign: TextAlign.justify,
                                    style: TextStyle(fontSize: 16, height: 1.4),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _infoChip(BuildContext context, String label, String value) {
    return _customChip(context, "$label: $value");
  }

  Widget _customChip(BuildContext context, String label) {
    return Material(
      color: chipBackgroundColor(context),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _infoBox(BuildContext context, String? value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: chipBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value ?? 'N/A',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _studioOrGenreList(List<dynamic>? items) {
    final itemList = items ?? [];
    if (itemList.isEmpty) {
      return _infoBox(context, 'N/A');
    }

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: itemList.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _customChip(context, item['name'] ?? 'N/A'),
          );
        }).toList(),
      ),
    );
  }
}