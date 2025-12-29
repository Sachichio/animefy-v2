import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/favorite_service.dart';
import '../widgets/comment_section.dart';

class DetailScreen extends StatefulWidget {
  /// Bisa dipanggil dua cara:
  /// 1) DetailScreen(anime: map, userId: ...)
  /// 2) Navigator.pushNamed(context, "/anime/detail", arguments: map)
  final Map<String, dynamic>? anime;
  final String? userId;

  const DetailScreen({
    super.key,
    this.anime,
    this.userId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // ============================
  // STATE
  // ============================
  Map<String, dynamic>? fullData;
  bool isLoadingDetail = true;

  bool isFavorite = false;
  bool _didInit = false; // to avoid double init in didChangeDependencies

  // Translation
  bool showIndonesian = false;
  String translatedSynopsis = '';
  bool isTranslating = false;

  // ============================
  // HELPERS TO ACCESS ANIME SOURCE
  // ============================
  /// anime passed either via constructor or via route arguments
  Map<String, dynamic> get passedAnime {
    // priority: widget.anime (constructor) > route args > empty map
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (widget.anime != null) return widget.anime!;
    if (routeArgs != null && routeArgs is Map<String, dynamic>) {
      return routeArgs;
    }
    if (routeArgs != null && routeArgs is Map) {
      // sometimes Map is not typed
      return Map<String, dynamic>.from(routeArgs);
    }
    return {};
  }

  int? get passedMalId {
    final a = passedAnime;
    if (a.containsKey('mal_id')) {
      final raw = a['mal_id'];
      if (raw is int) return raw;
      final parsed = int.tryParse(raw?.toString() ?? '');
      return parsed;
    }
    return null;
  }

  Map<String, dynamic> get dataToShow {
    // prefer fullData (fetched full endpoint), else fallback to passedAnime
    return fullData ?? passedAnime;
  }

  // ============================
  // FAVORITE
  // ============================
  Future<void> checkFavorite() async {
    try {
      final malId = passedMalId;
      if (malId == null) {
        setState(() => isFavorite = false);
        return;
      }

      final fav = widget.userId != null
          ? await FavoriteService.isFavoriteServer(widget.userId!, malId)
          : await FavoriteService.isFavoriteLocal(malId);

      if (mounted) setState(() => isFavorite = fav);
    } catch (e) {
      // ignore error but keep non-fatal
      if (mounted) setState(() => isFavorite = false);
    }
  }

  Future<void> toggleFavorite() async {
    try {
      final malId = passedMalId;
      if (malId == null) return;

      final dataToSave = fullData ?? passedAnime;
      final result = await FavoriteService.toggleFavorite(
        dataToSave,
        userId: widget.userId,
      );

      if (mounted) setState(() => isFavorite = result);
    } catch (e) {
      // ignore; optionally show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal toggle favorite: $e')),
        );
      }
    }
  }

  // ============================
  // DETAIL JIKAN
  // ============================
  Future<void> fetchDetail() async {
    setState(() => isLoadingDetail = true);

    try {
      final malId = passedMalId;
      if (malId == null) {
        // nothing to fetch
        if (mounted) setState(() => isLoadingDetail = false);
        return;
      }

      final url = Uri.parse("https://api.jikan.moe/v4/anime/$malId/full");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final extracted = jsonDecode(res.body);
        if (extracted != null && extracted['data'] is Map) {
          fullData = Map<String, dynamic>.from(extracted['data']);
        }
      }
    } catch (e) {
      // non-fatal
      debugPrint("Fetch detail error: $e");
    } finally {
      if (mounted) setState(() => isLoadingDetail = false);
    }
  }

  // ============================
  // TRANSLATION
  // ============================
  Future<String> translateText(String text, String targetLang) async {
    try {
      final encoded = Uri.encodeComponent(text);
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$targetLang&dt=t&q=$encoded',
      );

      final res = await http.get(url);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return (json[0] as List).map((e) => e[0]).join('');
      }
      return 'Terjemahan tidak tersedia.';
    } catch (_) {
      return 'Terjemahan tidak tersedia.';
    }
  }

  void toggleLanguage() async {
    final english = fullData?['synopsis'] ??
        passedAnime['synopsis'] ??
        'Tidak tersedia sinopsis.';

    if (!showIndonesian) {
      setState(() => isTranslating = true);
      final result = await translateText(english, 'id');
      if (!mounted) return;
      setState(() {
        translatedSynopsis = result;
        showIndonesian = true;
        isTranslating = false;
      });
    } else {
      setState(() => showIndonesian = false);
    }
  }

  // ============================
  // LIFECYCLE
  // ============================
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // do this once when widget enters tree and context is available
    if (!_didInit) {
      _didInit = true;
      // Kick off checkFavorite & fetchDetail (safe because we can access ModalRoute here)
      checkFavorite();
      fetchDetail();
    }
  }

  // ============================
  // HELPERS FOR UI
  // ============================
  String getImage(Map anime) {
    return anime['images']?['jpg']?['large_image_url'] ??
        anime['image_url'] ??
        anime['imageUrl'] ??
        'https://via.placeholder.com/300x400';
  }

  Color chipColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.grey.shade200;
  }

  List<String> normalizeList(List? list) {
    if (list == null) return [];
    return list.map<String>((e) {
      if (e is Map && e['name'] != null) return e['name'].toString();
      return e.toString();
    }).toList();
  }

  // ============================
  // BUILD
  // ============================
  @override
  Widget build(BuildContext context) {
    final anime = dataToShow;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final studios = normalizeList(anime['studios']);
    final genres = normalizeList(anime['genres']);

    final englishSynopsis =
        anime['synopsis'] ?? 'Tidak ada sinopsis tersedia.';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            backgroundColor: Colors.deepPurple,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  anime['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    getImage(anime),
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 65),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          getImage(anime),
                          height: 210,
                          fit: BoxFit.contain,
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
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    const Text("EN", style: TextStyle(color: Colors.white)),
                    Switch(
                      value: showIndonesian,
                      onChanged: (_) {
                        if (!isTranslating) toggleLanguage();
                      },
                      activeColor: Colors.white,
                    ),
                    const Text("ID", style: TextStyle(color: Colors.white)),
                  ],
                ),
              )
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _chip(context, "Type", anime['type']),
                            _chip(context, "Episode", anime['episodes']),
                            _chip(context, "Status", anime['status']),
                            _chip(context, "Score", anime['score']),
                            _chip(context, "Season", anime['season']),
                            _chip(context, "Duration", anime['duration']),
                          ],
                        ),

                        const SizedBox(height: 22),
                        _infoLabel("English"),
                        const SizedBox(height: 6),
                        _infoBox(anime['title_english'], isDark),

                        const SizedBox(height: 22),
                        _infoLabel("Japanese"),
                        const SizedBox(height: 6),
                        _infoBox(anime['title_japanese'], isDark),

                        const SizedBox(height: 22),
                        _infoLabel("Studio"),
                        const SizedBox(height: 6),
                        studios.isEmpty
                            ? _infoBox("N/A", isDark)
                            : Wrap(
                                spacing: 8,
                                children: studios
                                    .map((s) => Chip(
                                          label: Text(s),
                                          backgroundColor: chipColor(context),
                                        ))
                                    .toList(),
                              ),

                        const SizedBox(height: 22),
                        _infoLabel("Genre"),
                        const SizedBox(height: 6),
                        genres.isEmpty
                            ? _infoBox("N/A", isDark)
                            : Wrap(
                                spacing: 8,
                                children: genres
                                    .map((g) => Chip(
                                          label: Text(g),
                                          backgroundColor: chipColor(context),
                                        ))
                                    .toList(),
                              ),

                        const SizedBox(height: 28),
                        _infoLabel("Sinopsis"),
                        const SizedBox(height: 10),
                        isTranslating
                            ? const Center(child: CircularProgressIndicator())
                            : Text(
                                showIndonesian
                                    ? translatedSynopsis
                                    : englishSynopsis,
                                textAlign: TextAlign.justify,
                                style: const TextStyle(fontSize: 15),
                              ),

                        const SizedBox(height: 32),

                        // COMMENT SECTION
                        CommentSection(
                          malId: passedMalId ?? 0,
                          userId: widget.userId,
                        ),

                        const SizedBox(height: 32),
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

  Widget _chip(BuildContext context, String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text("$label: ${value ?? 'N/A'}"),
    );
  }

  Widget _infoLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _infoBox(String? value, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value ?? "N/A",
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}