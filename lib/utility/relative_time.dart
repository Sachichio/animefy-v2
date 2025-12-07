/// Utility untuk mengubah timestamp ISO menjadi waktu relatif.
/// Contoh output:
/// "2 menit lalu", "3 jam lalu", "Kemarin", "5 hari lalu"

class RelativeTime {
  static String format(String isoTimestamp) {
    try {
      final dateTime = DateTime.parse(isoTimestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inSeconds < 60) {
        return "baru saja";
      } else if (diff.inMinutes < 60) {
        return "${diff.inMinutes} menit lalu";
      } else if (diff.inHours < 24) {
        return "${diff.inHours} jam lalu";
      } else if (diff.inDays == 1) {
        return "Kemarin";
      } else if (diff.inDays < 7) {
        return "${diff.inDays} hari lalu";
      } else if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).floor();
        return "$weeks minggu lalu";
      } else if (diff.inDays < 365) {
        final months = (diff.inDays / 30).floor();
        return "$months bulan lalu";
      } else {
        final years = (diff.inDays / 365).floor();
        return "$years tahun lalu";
      }
    } catch (e) {
      // Jika parsing gagal, kembalikan timestamp original
      return isoTimestamp;
    }
  }
}