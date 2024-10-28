import 'dart:developer';
import 'package:aurora/utils/sources/source_base.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

class MangaNato implements SourceBase {
  @override
  String get baseUrl => 'https://chapmanganato.to/';

  @override
  String get sourceName => 'MangaNato';

  @override
  String get sourceVersion => '1.0';

  @override
  Future<Map<String, dynamic>> fetchMangaChapters(String mangaId) async {
    final String url = 'https://chapmanganato.to/$mangaId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final target = document.querySelector('.story-info-right');

        if (target == null) {
          log('Error: Could not find the story-info-right element.');
          return {};
        }

        final String title = target.querySelector('h1')?.text.trim() ?? 'N/A';
        final chapterElements =
            document.querySelectorAll('.panel-story-chapter-list .a-h');
        final List<Map<String, dynamic>> chapterList =
            chapterElements.map((element) {
          final title =
              element.querySelector('.chapter-name')?.text.trim() ?? 'N/A';
          final path =
              element.querySelector('.chapter-name')?.attributes['href'] ?? '';
          final views =
              element.querySelector('.chapter-view')?.text.trim() ?? 'N/A';
          final updatedAt =
              element.querySelector('.chapter-time')?.text.trim() ?? 'N/A';
          final number = path.split('/').last.split('-').last;

          return {
            'id': mangaId,
            'title': title,
            'path': path,
            'views': views,
            'updatedAt': updatedAt,
            'number': number,
          };
        }).toList();

        final metaData = {
          'id': chapterList[0]['path'].toString().split('/')[3],
          'title': title,
          'chapterList': chapterList,
        };

        log('Scraped Manga Info: ${metaData.toString()}');
        return metaData;
      } else {
        throw Exception(
            'Failed to load manga information. Status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error occurred while scraping manga info: ${e.toString()}');
      return {};
    }
  }

  @override
  Future<dynamic> fetchChapterImages({
    required String mangaId,
    required String chapterId,
  }) async {
    final url = 'https://chapmanganato.to/$mangaId/$chapterId';
    int index = 0;

    try {
      final response = await http.get(Uri.parse(url),
          headers: {'Referer': 'https://chapmanganato.to/'});
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final target = document.querySelector('.navi-change-chapter');

        final title = document
            .querySelector('.panel-chapter-info-top h1')
            ?.text
            .toLowerCase()
            .split('chapter')
            .first
            .trim()
            .toUpperCase();

        final currentChapter =
            'Chapter${document.querySelector('.panel-chapter-info-top h1')?.text.toLowerCase().split('chapter').last.toUpperCase()}';

        final chapterListIds = target?.querySelectorAll('option').map((option) {
              return {
                'id': 'chapter-${option.attributes['data-c']}',
                'name': option.text.trim(),
              };
            }).toList() ??
            [];

        final images = await Future.wait(document
            .querySelectorAll('.container-chapter-reader img')
            .map((img) async {
          final imgUrl = img.attributes['src'] ?? '';
          index++;
          return {
            'title': img.attributes['title'] ?? '',
            'image': imgUrl,
          };
        }).toList());

        final assets = {
          'title': title,
          'currentChapter': currentChapter,
          'chapterListIds': chapterListIds,
          'images': images,
          'totalImages': index,
        };

        log(assets.toString());
        return assets;
      } else {
        log('Failed to load chapter details, status code: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      log('Error: $e');
    }
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMangaSearchResults(
      String query) async {
    final String formattedQuery = query.replaceAll(' ', '_');
    final String url = 'https://manganato.com/search/story/$formattedQuery';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final searchItems =
            document.querySelectorAll('.panel-search-story .search-story-item');

        List<Map<String, dynamic>> mangaList = searchItems.map((element) {
          final titleElement = element.querySelector('.item-title');
          final String title = titleElement?.text.trim() ?? 'N/A';
          final String link = titleElement?.attributes['href'] ?? '';
          final String imageUrl =
              element.querySelector('.item-img img')?.attributes['src'] ?? '';
          final String rating =
              element.querySelector('.item-rate')?.text.trim() ?? 'N/A';
          final String author =
              element.querySelector('.item-author')?.text.trim() ?? 'N/A';
          final updatedElement = element.querySelectorAll('.item-time');
          final String updatedAt =
              updatedElement.isNotEmpty ? updatedElement[0].text.trim() : 'N/A';
          final String views =
              updatedElement.length > 1 ? updatedElement[1].text.trim() : 'N/A';
          final chapterElements = element.querySelectorAll('.item-chapter');
          final List<Map<String, String>> chapters =
              chapterElements.map((chapter) {
            return {
              'chapterTitle': chapter.text.trim(),
              'chapterLink': chapter.attributes['href'] ?? '',
            };
          }).toList();

          return {
            'id': link.toString().split('/').last,
            'title': title,
            'link': link,
            'imageUrl': imageUrl,
            'rating': rating,
            'author': author,
            'updatedAt': updatedAt,
            'views': views,
            'chapters': chapters,
          };
        }).toList();

        log('Scraped Search Data: ${mangaList.toString()}');
        return mangaList;
      } else {
        throw Exception(
            'Failed to load search results. Status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error occurred while scraping search data: ${e.toString()}');
      return [];
    }
  }
}
