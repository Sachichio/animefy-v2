import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/services/user_service.dart';
import '/utility/relative_time.dart';

class AdminManageCommentsScreen extends StatefulWidget {
  const AdminManageCommentsScreen({super.key});

  @override
  State<AdminManageCommentsScreen> createState() =>
      _AdminManageCommentsScreenState();
}

class _AdminManageCommentsScreenState extends State<AdminManageCommentsScreen> {
  final String baseUrl =
      "https://692c6b34c829d464006f84a7.mockapi.io/Comments";

  List comments = [];
  List filteredComments = [];

  final Map<String, String> usernameCache = {};
  final Map<int, String> animeTitleCache = {};

  bool isLoading = true;

  String searchQuery = "";
  String selectedAnime = "Semua";
  List<String> animeTitles = ["Semua"];

  @override
  void initState() {
    super.initState();
    fetchComments();
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
    } catch (e) {
      debugPrint("fetchAnimeTitleFromJikan error: $e");
    }
    return "Unknown Title";
  }

  Future<String> getAnimeDisplay(int malId) async {
    if (animeTitleCache.containsKey(malId)) return animeTitleCache[malId]!;

    final title = await fetchAnimeTitleFromJikan(malId);
    final display = "ID $malId (${title == "Unknown Title" ? "Unknown" : title})";
    animeTitleCache[malId] = display;
    return display;
  }

  Future<void> fetchComments() async {
    setState(() => isLoading = true);

    try {
      final res = await http.get(Uri.parse(baseUrl));
      if (res.statusCode == 200) {
        comments = jsonDecode(res.body) as List<dynamic>;

        comments.sort((a, b) =>
            b['timestamp'].toString().compareTo(a['timestamp'].toString()));

        final Set<String> animeDisplays = {};

        for (var c in comments) {
          final uid = (c['userId'] ?? "").toString();
          if (uid.isNotEmpty && !usernameCache.containsKey(uid)) {
            try {
              final uname = await UserService.getUsernameById(uid);
              usernameCache[uid] = uname ?? "Unknown";
            } catch (_) {
              usernameCache[uid] = "Unknown";
            }
          }

          final raw = c['mal_id'];
          final mal = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;

          if (mal > 0 && !animeTitleCache.containsKey(mal)) {
            final display = await getAnimeDisplay(mal);
            animeDisplays.add(display);
          } else if (mal > 0) {
            animeDisplays.add(animeTitleCache[mal]!);
          }
        }

        final sorted = animeDisplays.toList()..sort();
        animeTitles = ["Semua", ...sorted];

        filteredComments = List.from(comments);

        // FIX: pastikan selectedAnime tetap valid
        if (!animeTitles.contains(selectedAnime)) {
          selectedAnime = "Semua";
        }
      }
    } catch (e) {
      debugPrint("fetchComments error: $e");
    }

    if (mounted) setState(() => isLoading = false);
  }

  void filterComments() {
    final q = searchQuery.toLowerCase();

    setState(() {
      filteredComments = comments.where((c) {
        final uid = (c['userId'] ?? "").toString();
        final username = usernameCache[uid] ?? "Unknown";

        final commentText = (c['commentText'] ?? "").toLowerCase();

        final matchSearch = commentText.contains(q) ||
            username.toLowerCase().contains(q);

        final raw = c['mal_id'];
        final mal = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
        final animeDisplay =
            animeTitleCache[mal] ?? "ID $mal";

        final matchAnime = selectedAnime == "Semua"
            ? true
            : selectedAnime == animeDisplay;

        return matchSearch && matchAnime;
      }).toList();
    });
  }

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

        // FIX: Setelah delete, cek apakah selectedAnime masih valid
        if (!animeTitles.contains(selectedAnime)) {
          setState(() => selectedAnime = "Semua");
        }

        filterComments();
      }
    } catch (e) {
      debugPrint("deleteComment error: $e");
    }
  }

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
              } catch (e) {
                debugPrint("editComment error: $e");
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Komentar User",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari komentar atau username...",
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: selectedAnime,
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

                          final userId = c["userId"].toString();
                          final user = usernameCache[userId] ?? "Unknown";

                          final raw = c['mal_id'];
                          final mal =
                              raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
                          final animeDisplay =
                              animeTitleCache[mal] ?? "ID $mal";

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(c['commentText'] ?? "",
                                  style: const TextStyle(fontSize: 16)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text("User: $user"),
                                  Text("Anime: $animeDisplay"),
                                  Text("Waktu: ${RelativeTime.format(c['timestamp'])}"),
                                  Text(
                                    (c['edited'] == true) ? "Edited" : "Original",
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