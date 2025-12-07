// detail_screen.dart
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
  // favorite
  bool isFavorite = false;

  // translation
  bool showIndonesian = false;
  String translatedSynopsis = '';
  bool isTranslating = false;

  // detail dari Jikan (full)
  Map<String, dynamic>? fullData;
  bool isLoadingDetail = true;

  // comments
  final String _commentsApi = 'https://692c6b34c829d464006f84a7.mockapi.io/Comments';
  List<Map<String, dynamic>> comments = [];
  bool isLoadingComments = true;
  bool isPostingComment = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkFavorite();
    fetchDetail();
    fetchComments(); // load comments immediately (will use mal_id from widget.anime)
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ----------------------------
  // FAVORITE
  // ----------------------------
  Future<void> checkFavorite() async {
    try {
      final fav = widget.userId != null
          ? await FavoriteService.isFavoriteServer(widget.userId!, widget.anime['mal_id'])
          : await FavoriteService.isFavoriteLocal(widget.anime['mal_id']);
      if (mounted) setState(() => isFavorite = fav);
    } catch (e) {
      // ignore, tetap tampilkan screen
      print("Error checkFavorite: $e");
    }
  }

  Future<void> toggleFavorite() async {
    try {
      final dataToSave = fullData ?? widget.anime;
      final result = await FavoriteService.toggleFavorite(dataToSave, userId: widget.userId);
      if (mounted) setState(() => isFavorite = result);
    } catch (e) {
      print("Error toggleFavorite: $e");
    }
  }

  // ----------------------------
  // FETCH DETAIL DARI JIKAN
  // ----------------------------
  Future<void> fetchDetail() async {
    try {
      final malId = widget.anime['mal_id'];
      if (malId == null) {
        if (mounted) setState(() => isLoadingDetail = false);
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
      } else {
        if (mounted) setState(() => isLoadingDetail = false);
      }
    } catch (e) {
      print("Fetch detail error: $e");
      if (mounted) setState(() => isLoadingDetail = false);
    }
  }

  // ----------------------------
  // TRANSLATE (Google translate public endpoint)
  // ----------------------------
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

  // ----------------------------
  // COMMENTS: fetch & post
  // ----------------------------
  Future<void> fetchComments() async {
    setState(() {
      isLoadingComments = true;
    });

    try {
      final malId = widget.anime['mal_id'];
      if (malId == null) {
        setState(() {
          comments = [];
          isLoadingComments = false;
        });
        return;
      }

      final Uri url = Uri.parse('$_commentsApi?mal_id=$malId');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        // normalize to List<Map<String, dynamic>>
        final List<Map<String, dynamic>> parsed = data.map<Map<String, dynamic>>((e) {
          if (e is Map<String, dynamic>) return e;
          return Map<String, dynamic>.from(e);
        }).toList();

        // Sort by timestamp desc (newest first) if timestamp present
        parsed.sort((a, b) {
          final ta = a['timestamp']?.toString() ?? '';
          final tb = b['timestamp']?.toString() ?? '';
          return tb.compareTo(ta);
        });

        if (mounted) setState(() {
          comments = parsed;
          isLoadingComments = false;
        });
      } else {
        if (mounted) setState(() {
          comments = [];
          isLoadingComments = false;
        });
      }
    } catch (e) {
      print("Error fetchComments: $e");
      if (mounted) setState(() {
        comments = [];
        isLoadingComments = false;
      });
    }
  }

  Future<void> postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (widget.userId == null) {
      // Should not happen because input hidden when not logged in
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap login terlebih dahulu.')));
      return;
    }

    setState(() => isPostingComment = true);

    try {
      final malId = widget.anime['mal_id'];
      final payload = {
        'userId': widget.userId,
        'mal_id': malId,
        'commentText': text,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      final res = await http.post(
        Uri.parse(_commentsApi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        _commentController.clear();
        await fetchComments();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Komentar terkirim.')));
      } else {
        print('Post comment failed: ${res.statusCode} ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim komentar.')));
      }
    } catch (e) {
      print('Error postComment: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim komentar.')));
    } finally {
      if (mounted) setState(() => isPostingComment = false);
    }
  }

  // ----------------------------
  // HELPERS UI / NORMALIZATION
  // ----------------------------
  String getImage(Map anime) {
    return anime['image_url'] ??
        anime['imageUrl'] ??
        anime['images']?['jpg']?['image_url'] ??
        'https://via.placeholder.com/300x400';
  }

  // chip / card colors: dark-like feel for light mode too (not black)
  Color chipBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200;
  }

  Color cardBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white;
  }

  Color titleBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.7);
  }

  // Studio/genre item -> accept: list of maps with name OR list of strings
  List<String> normalizeList(List<dynamic>? input) {
    if (input == null) return [];
    return input.map<String>((e) {
      if (e == null) return '';
      if (e is String) return e;
      if (e is Map && e.containsKey('name')) return e['name']?.toString() ?? '';
      return e.toString();
    }).where((s) => s.isNotEmpty).toList();
  }

  // responsive title: use softWrap + maxLines + ellipsis
  Widget buildResponsiveTitle(String title, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      // allow up to 2 lines in appbar title area, with ellipsis
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: constraints.maxWidth),
        child: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            shadows: [const Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1, 1))],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
      );
    });
  }

  // ----------------------------
  // BUILD
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    final anime = fullData ?? widget.anime;
    final englishSynopsis = anime['synopsis'] ?? 'Tidak tersedia sinopsis.';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final studios = normalizeList(anime['studios'] as List<dynamic>?);
    final genres = normalizeList(anime['genres'] as List<dynamic>?);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            backgroundColor: Colors.deepPurple,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Kembali',
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: titleBackgroundColor(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: buildResponsiveTitle(anime['title']?.toString() ?? 'Unknown', isDark),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    getImage(anime),
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.28),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (_, __, ___) => Container(color: Colors.black12),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  // main poster in the middle (slightly larger)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          getImage(anime),
                          fit: BoxFit.contain,
                          height: 210, // sedikit diperbesar dari sebelumnya
                          errorBuilder: (_, __, ___) => Container(
                            height: 210,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image, size: 80),
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
                tooltip: isFavorite ? 'Unfavorite' : 'Add to favorites',
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

          // content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: cardBackgroundColor(context),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // chips (type, episodes, status, score, season, duration)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _infoChip(context, 'Type', anime['type']?.toString()),
                              _infoChip(context, 'Episode', anime['episodes']?.toString()),
                              _infoChip(context, 'Status', anime['status']?.toString()),
                              _infoChip(context, 'Score', anime['score']?.toString()),
                              _infoChip(context, 'Season', anime['season']?.toString()),
                              _infoChip(context, 'Duration', anime['duration']?.toString()),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // Title English
                          Text('English', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          _infoBox(context, anime['title_english']?.toString()),

                          const SizedBox(height: 18),

                          // Title Japanese
                          Text('Japanese', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          _infoBox(context, anime['title_japanese']?.toString()),

                          const SizedBox(height: 18),

                          // studios
                          Text('Studio', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          studios.isEmpty ? _infoBox(context, 'N/A') : Wrap(
                            spacing: 8,
                            children: studios.map((s) => Chip(
                              label: Text(s),
                              backgroundColor: chipBackgroundColor(context),
                            )).toList(),
                          ),

                          const SizedBox(height: 16),

                          // genres
                          Text('Genre', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          genres.isEmpty ? _infoBox(context, 'N/A') : Wrap(
                            spacing: 8,
                            children: genres.map((g) => Chip(
                              label: Text(g),
                              backgroundColor: chipBackgroundColor(context),
                            )).toList(),
                          ),

                          const SizedBox(height: 24),

                          // synopsis
                          Text(
                            'Sinopsis',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          isTranslating
                              ? const Center(child: CircularProgressIndicator())
                              : Text(
                                  showIndonesian ? translatedSynopsis : englishSynopsis,
                                  textAlign: TextAlign.justify,
                                  style: const TextStyle(fontSize: 15, height: 1.5),
                                ),

                          const SizedBox(height: 24),

                          // ----------------------------
                          // COMMENTS SECTION (after synopsis)
                          // ----------------------------
                          Divider(color: isDark ? Colors.white10 : Colors.black12),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Komentar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              // refresh button
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Refresh komentar',
                                onPressed: fetchComments,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // input area (login prompt or input)
                          if (widget.userId == null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: chipBackgroundColor(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text('Silakan login untuk berkomentar.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))),
                                  ElevatedButton(
                                    onPressed: () {
                                      // navigate to login route - change '/login' jika berbeda di app-mu
                                      Navigator.pushNamed(context, '/login').then((_) {
                                        // setelah kembali dari login, coba update favorite & comments
                                        checkFavorite();
                                        fetchComments();
                                      });
                                    },
                                    child: const Text('Login'),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _commentController,
                                  minLines: 1,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: chipBackgroundColor(context),
                                    hintText: 'Tulis komentar kamu...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: isPostingComment ? null : () => postComment(),
                                      icon: isPostingComment ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                                      label: const Text('Kirim'),
                                    ),
                                    const SizedBox(width: 12),
                                    TextButton(
                                      onPressed: () {
                                        _commentController.clear();
                                      },
                                      child: const Text('Bersihkan'),
                                    ),
                                  ],
                                )
                              ],
                            ),

                          const SizedBox(height: 16),

                          // comments list
                          isLoadingComments
                              ? const Center(child: CircularProgressIndicator())
                              : comments.isEmpty
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: chipBackgroundColor(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Belum ada komentar. Jadilah yang pertama!'),
                                    )
                                  : Column(
                                      children: comments.map((c) {
                                        final userId = c['userId']?.toString() ?? 'Unknown';
                                        final text = c['commentText']?.toString() ?? '';
                                        final ts = c['timestamp']?.toString() ?? '';
                                        // format ts simple: yyyy-mm-dd hh:mm
                                        String niceTs = ts;
                                        try {
                                          if (ts.isNotEmpty) {
                                            final dt = DateTime.parse(ts);
                                            niceTs = '${dt.toLocal().toString().split(".")[0]}';
                                          }
                                        } catch (_) {}

                                        return Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('User $userId', style: const TextStyle(fontWeight: FontWeight.w700)),
                                                  Text(niceTs, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(text),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // small helper: info chip
  Widget _infoChip(BuildContext context, String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

  // info box (English / Japanese)
  Widget _infoBox(BuildContext context, String? value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.grey.shade200),
      ),
      child: Text(
        value ?? 'N/A',
        style: TextStyle(
          fontSize: 15,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}