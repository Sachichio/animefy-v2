import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'anime_studio_list_screen.dart';

class AnimeStudioScreen extends StatefulWidget {
  const AnimeStudioScreen({super.key});

  @override
  State<AnimeStudioScreen> createState() => _AnimeStudioScreenState();
}

class _AnimeStudioScreenState extends State<AnimeStudioScreen> {
  List<dynamic> studios = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStudios();
  }

  Future<void> fetchStudios() async {
    final url = Uri.parse("https://api.jikan.moe/v4/producers");

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        studios = data["data"] ?? [];
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  // Warna avatar berdasarkan nama studio
  Color avatarColor(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hash = name.hashCode;
    final r = (hash & 0xFF);
    final g = ((hash >> 8) & 0xFF);
    final b = ((hash >> 16) & 0xFF);

    final base = Color.fromARGB(255, r, g, b);
    return isDark ? base.withOpacity(0.6) : base.withOpacity(0.8);
  }

  // Inisial studio (A-1 Pictures → A1)
  String studioInitial(String name) {
    final words = name.split(' ');
    if (words.length == 1) {
      return name.length > 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    }
    return words.map((e) => e[0]).take(2).join().toUpperCase();
  }

  // Card background adaptif
  Color cardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade900 : Colors.grey.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Studio Anime",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: studios.length,
              itemBuilder: (context, index) {
                final s = studios[index];

                final String name = 
                    s["titles"]?[0]?["title"] ??
                    s["name"] ??
                    "Unknown";

                final int count = s["count"] ?? 0;

                return Container(
                  decoration: BoxDecoration(
                    color: cardColor(context),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 14),

                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: avatarColor(name),
                      child: Text(
                        studioInitial(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    title: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    subtitle: Text(
                      "$count anime",
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .color!
                            .withOpacity(0.7),
                      ),
                    ),

                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnimeStudioListScreen(
                            studioId: s["mal_id"],
                            studioName: name,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}