import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AnimeFetchPage = Future<Map<String, dynamic>> Function(int page);

class PaginatedAnimeScreen extends StatefulWidget {
  final String title;
  final AnimeFetchPage fetchPage;
  final int initialPage;

  const PaginatedAnimeScreen({
    Key? key,
    required this.title,
    required this.fetchPage,
    this.initialPage = 1,
  }) : super(key: key);

  @override
  State<PaginatedAnimeScreen> createState() => _PaginatedAnimeScreenState();
}

class _PaginatedAnimeScreenState extends State<PaginatedAnimeScreen> {
  int page = 1;
  bool isLoading = true;
  List<dynamic> items = [];
  int lastPage = 1;

  @override
  void initState() {
    super.initState();
    page = widget.initialPage;
    WidgetsBinding.instance.addPostFrameCallback((_) => loadPage(page));
  }

  Future<void> loadPage(int p) async {
    setState(() => isLoading = true);

    try {
      final result = await widget.fetchPage(p);
      final List<dynamic> data = result['data'] as List<dynamic>? ?? [];
      final int lp = result['lastPage'] as int? ?? p + (data.isEmpty ? 0 : 1);

      setState(() {
        items = data;
        lastPage = lp;
        page = p;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildItem(dynamic anime) {
    // SKIP HENTAI
    final genres = (anime['genres'] as List?)
            ?.map((g) => g['name']?.toString().toLowerCase())
            .toList() ??
        [];
    if (genres.contains("hentai")) return const SizedBox.shrink();

    final title = (anime['title'] ?? anime['title_english'] ?? 'Unknown').toString();
    final image = anime['images']?['jpg']?['image_url'] ??
        anime['image_url'] ??
        '';
    final score = anime['score']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: image.isNotEmpty
              ? FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: image,
                  width: 52,
                  height: 78,
                  fit: BoxFit.cover,
                )
              : Container(width: 52, height: 78, color: Colors.grey.shade300),
        ),
        title: Text(title),
        subtitle: Text('Score: $score'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString("userId");

          Navigator.pushNamed(
            context,
            "/anime/detail",
            arguments: {
              "anime": anime,
              "userId": userId,
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Pagination controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: page > 1 && !isLoading ? () => loadPage(page - 1) : null,
                  child: const Text("Prev"),
                ),
                const SizedBox(width: 12),
                Text("Halaman $page"),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: !isLoading ? () => loadPage(page + 1) : null,
                  child: const Text("Next"),
                ),
                const Spacer(),
                SizedBox(
                  width: 90,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "page",
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    onSubmitted: (v) {
                      final p = int.tryParse(v) ?? page;
                      if (p > 0) loadPage(p);
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(child: Text('Tidak ada data pada halaman $page'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) => _buildItem(items[i]),
                      ),
          ),
        ],
      ),
    );
  }
}