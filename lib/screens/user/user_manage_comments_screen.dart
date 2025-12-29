import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/utility/relative_time.dart';

class UserManageCommentsScreen extends StatefulWidget {
  const UserManageCommentsScreen({super.key});

  @override
  State<UserManageCommentsScreen> createState() =>
      _UserManageCommentsScreenState();
}

class _UserManageCommentsScreenState extends State<UserManageCommentsScreen> {
  final String baseUrl =
      "https://692c6b34c829d464006f84a7.mockapi.io/Comments";

  List comments = [];
  List filteredComments = [];

  bool isLoading = true;

  String searchQuery = "";
  String selectedAnime = "Semua";
  List<String> animeTitles = ["Semua"];

  String userId = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId") ?? "";
    await fetchComments();
  }

  Future<String> fetchAnimeTitleFromJikan(int malId) async {
    if (malId <= 0) return "Unknown Title";

    final url = "https://api.jikan.moe/v4/anime/$malId";

    try {
      final r = await http.get(Uri.parse(url));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final title = data?['data']?['title'];
        if (title is String && title.isNotEmpty) return title;
      }
    } catch (_) {}

    return "Unknown Title";
  }

  final Map<int, String> animeTitleCache = {};

  Future<String> getAnimeDisplay(int malId) async {
    if (animeTitleCache.containsKey(malId)) {
      return animeTitleCache[malId]!;
    }

    final title = await fetchAnimeTitleFromJikan(malId);
    final display =
        "ID $malId (${title == "Unknown Title" ? "Unknown" : title})";
    animeTitleCache[malId] = display;
    return display;
  }

  // ==========================
  // FETCH KOMENTAR USER
  // ==========================
  Future<void> fetchComments() async {
    setState(() => isLoading = true);

    try {
      final res = await http.get(Uri.parse(baseUrl));
      if (res.statusCode == 200) {
        final allComments = jsonDecode(res.body) as List<dynamic>;

        // FILTER hanya komentar user ini
        comments = allComments
            .where((c) => c['userId'].toString() == userId)
            .toList();

        comments.sort((a, b) =>
            b['timestamp'].toString().compareTo(a['timestamp'].toString()));

        final Set<String> animeDisplays = {};

        for (var c in comments) {
          final raw = c['mal_id'];
          final mal = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;

          if (mal > 0) {
            final display = await getAnimeDisplay(mal);
            animeDisplays.add(display);
          }
        }

        final sorted = animeDisplays.toList()..sort();
        animeTitles = ["Semua", ...sorted];

        // FIX PRO: pastikan selectedAnime VALID
        if (!animeTitles.contains(selectedAnime)) {
          selectedAnime = "Semua";
        }

        filteredComments = List.from(comments);
      }
    } catch (_) {}

    if (mounted) setState(() => isLoading = false);
  }

  // ==========================
  // FILTER KOMENTAR
  // ==========================
  void filterComments() {
    final q = searchQuery.toLowerCase();

    setState(() {
      filteredComments = comments.where((c) {
        final commentText = (c['commentText'] ?? "").toLowerCase();
        final matchSearch = commentText.contains(q);

        final raw = c['mal_id'];
        final mal = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
        final animeDisplay = animeTitleCache[mal] ?? "ID $mal";

        final matchAnime =
            (selectedAnime == "Semua") || (selectedAnime == animeDisplay);

        return matchSearch && matchAnime;
      }).toList();
    });
  }

  // ==========================
  // KONFIRMASI HAPUS
  // ==========================
  Future<bool> confirmDelete(String text) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Hapus Komentar"),
            content: Text("Yakin ingin menghapus komentar ini?\n\n\"$text\""),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Hapus")),
            ],
          ),
        ) ??
        false;
  }

  // ==========================
  // HAPUS KOMENTAR
  // ==========================
  Future<void> deleteComment(String id, String text) async {
    final ok = await confirmDelete(text);
    if (!ok) return;

    try {
      final res = await http.delete(Uri.parse("$baseUrl/$id"));
      if (res.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Komentar berhasil dihapus")),
        );

        await fetchComments();

        // FIX PRO: setelah delete, validasi dropdown lagi
        if (!animeTitles.contains(selectedAnime)) {
          setState(() => selectedAnime = "Semua");
        }

        filterComments();
      }
    } catch (_) {}
  }

  // ==========================
  // EDIT KOMENTAR
  // ==========================
  void editCommentDialog(Map comment) {
    final ctrl = TextEditingController(text: comment["commentText"]);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Komentar"),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), hintText: "Edit komentar..."),
        ),
        actions: [
          TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text("Simpan"),
            onPressed: () async {
              final body = {
                "commentText": ctrl.text.trim(),
                "edited": true,
                "timestamp": comment["timestamp"],
                "userId": comment["userId"],
                "mal_id": comment["mal_id"],
              };

              try {
                final res = await http.put(
                  Uri.parse("$baseUrl/${comment['id']}"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode(body),
                );

                if (res.statusCode == 200) {
                  if (!mounted) return;
                  Navigator.pop(context);

                  await fetchComments();
                  filterComments();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Komentar diperbarui")),
                  );
                }
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  // ==========================
  // UI / WIDGET
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Komentar Saya",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari komentar...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) {
                searchQuery = v;
                filterComments();
              },
            ),
          ),

          // Filter Anime
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: animeTitles.contains(selectedAnime)
                  ? selectedAnime
                  : "Semua", // FIX PRO: Aman
              items: animeTitles
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                selectedAnime = v ?? "Semua";
                filterComments();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Filter anime",
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredComments.isEmpty
                    ? const Center(child: Text("Tidak ada komentar"))
                    : ListView.builder(
                        itemCount: filteredComments.length,
                        itemBuilder: (_, i) {
                          final c = filteredComments[i];

                          final raw = c['mal_id'];
                          final mal = raw is int
                              ? raw
                              : int.tryParse(raw.toString()) ?? 0;
                          final animeDisplay =
                              animeTitleCache[mal] ?? "ID $mal";

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(
                                c['commentText'] ?? "",
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text("Anime: $animeDisplay"),
                                  Text("Waktu: ${RelativeTime.format(c['timestamp'])}"),
                                  Text(
                                    (c['edited'] == true)
                                        ? "Edited"
                                        : "Original",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c['edited'] == true
                                          ? Colors.orange
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          editCommentDialog(c)),
                                  IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => deleteComment(
                                          c['id'].toString(),
                                          c['commentText'])),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}