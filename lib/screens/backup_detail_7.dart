import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/favorite_service.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> anime;
  final String? userId;

  const DetailScreen({super.key, required this.anime, this.userId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isFavorite = false;
  bool showIndonesian = false;
  String translatedSynopsis = '';
  bool isTranslating = false;

  Map<String, dynamic>? fullData;
  bool isLoadingDetail = true;

  @override
  void initState() {
    super.initState();
    checkFavorite();
    fetchDetail();
  }

  Future<void> checkFavorite() async {
    bool fav = widget.userId != null
        ? await FavoriteService.isFavoriteServer(widget.userId!, widget.anime['mal_id'])
        : await FavoriteService.isFavoriteLocal(widget.anime['mal_id']);
    if (mounted) setState(() => isFavorite = fav);
  }

  Future<void> toggleFavorite() async {
    final dataToSave = fullData ?? widget.anime;
    final result = await FavoriteService.toggleFavorite(dataToSave, userId: widget.userId);
    if (mounted) setState(() => isFavorite = result);
  }

  Future<void> fetchDetail() async {
    try {
      final malId = widget.anime['mal_id'];
      if (malId == null) {
        setState(() => isLoadingDetail = false);
        return;
      }
      final url = Uri.parse("https://api.jikan.moe/v4/anime/$malId/full");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        if (mounted) setState(() {
          fullData = data;
          isLoadingDetail = false;
        });
      }
    } catch (e) {
      print("Fetch detail error: $e");
      if (mounted) setState(() => isLoadingDetail = false);
    }
  }

  Future<String> translateText(String text, String targetLang) async {
    try {
      final encodedText = Uri.encodeComponent(text);
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$targetLang&dt=t&q=$encodedText',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(res.body);
        return (jsonResponse[0] as List).map((e) => e[0]).join('');
      }
      return 'Terjemahan tidak tersedia.';
    } catch (e) {
      return 'Terjemahan tidak tersedia.';
    }
  }

  void toggleLanguage() async {
    final englishSynopsis = fullData?['synopsis'] ?? widget.anime['synopsis'] ?? 'Tidak tersedia sinopsis.';
    if (!showIndonesian) {
      setState(() => isTranslating = true);
      final result = await translateText(englishSynopsis, 'id');
      if (mounted) setState(() {
        translatedSynopsis = result;
        showIndonesian = true;
        isTranslating = false;
      });
    } else {
      setState(() => showIndonesian = false);
    }
  }

  Color chipBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final anime = fullData ?? widget.anime;
    final englishSynopsis = anime['synopsis'] ?? 'Tidak tersedia sinopsis.';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: Colors.deepPurple,
            leading: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
              title: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  anime['title'] ?? 'Unknown',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 3, color: Colors.black38, offset: Offset(1, 1))],
                  ),
                  softWrap: true,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    anime['images']?['jpg']?['image_url'] ?? '',
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (_, __, ___) => Container(color: Colors.black26),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          anime['images']?['jpg']?['image_url'] ?? '',
                          fit: BoxFit.contain,
                          height: 180,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: Colors.grey.shade300,
                            child: Icon(Icons.broken_image, size: 80),
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Text('EN', style: TextStyle(color: showIndonesian ? Colors.white54 : Colors.white)),
                    Switch(
                      value: showIndonesian,
                      activeColor: Colors.white,
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white30,
                      onChanged: (val) {
                        if (!isTranslating) toggleLanguage();
                      },
                    ),
                    Text('ID', style: TextStyle(color: showIndonesian ? Colors.white : Colors.white54)),
                  ],
                ),
              )
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).cardColor,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _infoChip(context, 'Type', anime['type']),
                            _infoChip(context, 'Episode', anime['episodes']?.toString()),
                            _infoChip(context, 'Status', anime['status']),
                            _infoChip(context, 'Score', anime['score']?.toString()),
                            _infoChip(context, 'Season', anime['season']),
                            _infoChip(context, 'Duration', anime['duration']),
                          ],
                        ),
                        SizedBox(height: 25),
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
                        _studioOrGenreList(context, anime['studios'], withColon: true),
                        SizedBox(height: 20),
                        Text('Genre', style: Theme.of(context).textTheme.titleMedium),
                        SizedBox(height: 8),
                        _studioOrGenreList(context, anime['genres'], withColon: true),
                        SizedBox(height: 35),
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
                )
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(BuildContext context, String label, String? value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: chipBackgroundColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: ${value ?? "N/A"}',
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w600),
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
      child: Text(value ?? 'N/A', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _studioOrGenreList(BuildContext context, List<dynamic>? items, {bool withColon = false}) {
    final list = items ?? [];
    if (list.isEmpty) return _infoBox(context, 'N/A');

    return Wrap(
      spacing: 8,
      children: list.map((item) {
        final name = item['name'] ?? item.toString();
        return Chip(
          label: Text(withColon ? '$name:' : name),
          backgroundColor: chipBackgroundColor(context),
        );
      }).toList(),
    );
  }
}