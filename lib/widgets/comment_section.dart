import 'package:flutter/material.dart';
import '../services/comment_service.dart';
import '../services/user_service.dart';
import '../utility/relative_time.dart';

class CommentSection extends StatefulWidget {
  final int malId;
  final String? userId; // null = belum login

  const CommentSection({
    super.key,
    required this.malId,
    this.userId,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  List<dynamic> comments = [];

  Map<String, String> usernameCache = {}; // userId -> username
  Map<String, String> userRoleCache = {}; // userId -> role
  Map<String, String?> avatarCache = {}; // userId -> avatar url

  bool isLoading = true;
  bool isSending = false;

  String loginUserRole = "user";

  final TextEditingController commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserRole();
    loadComments();
  }

  // ============================================================
  // LOAD ROLE USER LOGIN
  // ============================================================
  Future<void> loadUserRole() async {
    if (widget.userId != null) {
      final role = await UserService.getUserRole(widget.userId!);
      loginUserRole = role ?? "user";
      setState(() {});
    }
  }

  // ============================================================
  // LOAD COMMENT + USER DATA (username, role, avatar)
  // ============================================================
  Future<void> loadComments() async {
    setState(() => isLoading = true);

    try {
      final data = await CommentService.getComments(widget.malId);

      for (var c in data) {
        final uid = c['userId'];

        if (uid == null) continue;

        // Username cache
        if (!usernameCache.containsKey(uid)) {
          final name = await UserService.getUsernameById(uid);
          usernameCache[uid] = name ?? "User $uid";
        }

        // Role cache
        if (!userRoleCache.containsKey(uid)) {
          final role = await UserService.getUserRole(uid);
          userRoleCache[uid] = role ?? "user";
        }

        // Avatar cache
        if (!avatarCache.containsKey(uid)) {
          final avatar = await CommentService.getUserAvatar(uid);
          avatarCache[uid] = avatar; // bisa null = nanti fallback
        }
      }

      if (!mounted) return;

      setState(() {
        comments = data.reversed.toList(); // Komentar terbaru di atas
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print("Load comments error: $e");
      setState(() => isLoading = false);
    }
  }

  // ============================================================
  // SEND COMMENT
  // ============================================================
  Future<void> sendComment() async {
    if (commentCtrl.text.trim().isEmpty) return;

    setState(() => isSending = true);

    final ok = await CommentService.addComment(
      widget.userId!,
      widget.malId,
      commentCtrl.text.trim(),
    );

    if (ok) {
      commentCtrl.clear();
      await loadComments();
    }

    if (mounted) setState(() => isSending = false);
  }

  // ============================================================
  // EDIT COMMENT
  // ============================================================
  Future<void> showEditDialog(Map c) async {
    final TextEditingController editCtrl =
        TextEditingController(text: c['commentText']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Komentar"),
          content: TextField(
            controller: editCtrl,
            maxLines: null,
            decoration: const InputDecoration(hintText: "Tulis komentar baru..."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = await CommentService.editComment(
                  c['id'],
                  editCtrl.text.trim(),
                );

                if (updated) {
                  Navigator.pop(context);
                  await loadComments();
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DELETE COMMENT
  // ============================================================
  Future<void> showDeleteDialog(Map c) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hapus Komentar"),
          content: const Text("Yakin ingin menghapus komentar ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final deleted = await CommentService.deleteComment(c['id']);
                if (deleted) {
                  Navigator.pop(context);
                  await loadComments();
                }
              },
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MAIN UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Text(
          "Komentar",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 15),

        widget.userId == null
            ? _buildLoginBox(isDark)
            : _buildCommentForm(isDark),

        const SizedBox(height: 20),

        isLoading
            ? const Center(child: CircularProgressIndicator())
            : comments.isEmpty
                ? _buildEmptyMessage(isDark)
                : _buildCommentList(isDark),
      ],
    );
  }

  // ============================================================
  // LOGIN BOX
  // ============================================================
  Widget _buildLoginBox(bool isDark) {
    final Color box = isDark ? Colors.yellow.shade700 : Colors.deepPurple.shade100;
    final Color textColor = isDark ? Colors.black : Colors.deepPurple.shade900;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: box,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 30, color: textColor),
          const SizedBox(height: 10),
          Text(
            "Login untuk menambahkan komentar",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: textColor,
              foregroundColor: isDark ? Colors.yellow.shade700 : Colors.white,
            ),
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMENT FORM
  // ============================================================
  Widget _buildCommentForm(bool isDark) {
    return Column(
      children: [
        TextField(
          controller: commentCtrl,
          maxLines: null,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "Tulis komentar...",
            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            filled: true,
            fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: isSending ? null : sendComment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: isSending
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Kirim"),
          ),
        )
      ],
    );
  }

  // ============================================================
  // EMPTY MESSAGE
  // ============================================================
  Widget _buildEmptyMessage(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Text(
          "Belum ada komentar.",
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ============================================================
  // COMMENT LIST
  // ============================================================
  Widget _buildCommentList(bool isDark) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, i) {
        final c = comments[i];
        final uid = c['userId'];

        final username = usernameCache[uid] ?? "Unknown";
        final userRole = userRoleCache[uid] ?? "user";

        final String? avatarUrl = avatarCache[uid];
        final String fallbackAvatar =
            "https://ui-avatars.com/api/?name=$username&background=random";

        final time = RelativeTime.format(c['timestamp'] ?? "");

        final bool isOwner = widget.userId == uid;
        final bool isAdmin = loginUserRole == "admin";

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =======================
              // AVATAR USER
              // =======================
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  avatarUrl?.isNotEmpty == true ? avatarUrl! : fallbackAvatar,
                ),
              ),

              const SizedBox(width: 12),

              // =======================
              // COMMENT BODY
              // =======================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // USERNAME + BADGE
                    Row(
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),

                        if (userRole == "admin")
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "admin",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // TIME + edited
                    Row(
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        if (c['edited'] == true)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              "(edited)",
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      c['commentText'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // =======================
              // MENU TOMBOL EDIT / DELETE
              // =======================
              if (isOwner || isAdmin)
                PopupMenuButton(
                  onSelected: (value) {
                    if (value == "edit") showEditDialog(c);
                    if (value == "delete") showDeleteDialog(c);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: "edit", child: Text("Edit")),
                    PopupMenuItem(value: "delete", child: Text("Hapus")),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}