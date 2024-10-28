import 'package:aurora/utils/scrapers/manga/mangabat/mangabat.dart';
import 'package:aurora/utils/scrapers/manga/mangakakalot%20(unofficial)/scraper_all.dart';
import 'package:aurora/utils/scrapers/manga/mangakakalot/mangakakalot.dart';
import 'package:aurora/utils/scrapers/manga/manganato/manganato.dart';

class MangaSourceHandler {
  final Map<String, dynamic> sourceMap = {
    "MangaKakalot (Unofficial)": MangaKakalotUnofficial(),
    "MangaKakalot": MangaKakalot(),
    "MangaBat": MangaBat(),
    "MangaNato": MangaNato(),
    // "Bato": Bato(),
  };

  void fetchMangaChapters(
      String selectedSource, String mangaId, String chapterId) {
    final source = sourceMap[selectedSource];
    if (source != null) {
      source.fetchMangaChapters(mangaId, chapterId);
    } else {
      print("Source not available");
    }
  }

  void fetchMangaSearchResults(String selectedSource, String query) {
    final source = sourceMap[selectedSource];
    if (source != null) {
      source.fetchMangaSearchResults(query);
    } else {
      print("Source not available");
    }
  }
}
