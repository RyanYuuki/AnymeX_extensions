import 'dart:developer';
import 'package:aurora/utils/scrapers/manga/helper/jaro_helper.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

class MangaKakalot {
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

  Future<List<Map<String, dynamic>>> fetchMangaSearchResults(
      String query) async {
    final String formattedQuery = query.replaceAll(' ', '_');
    final url = 'https://mangakakalot.com/search/story/$formattedQuery';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = parse(response.body);
      final mangaList = <Map<String, dynamic>>[];

      document.querySelectorAll('.story_item').forEach((element) {
        final titleElement = element.querySelector('.story_name > a');
        final title = titleElement?.text.trim();
        final link = titleElement?.attributes['href'];
        final image = element.querySelector('img')?.attributes['src'];

        final chapters =
            element.querySelectorAll('.story_chapter').map((chapterElement) {
          final chapterTitle = chapterElement.text.trim();
          final chapterLink =
              chapterElement.querySelector('a')?.attributes['href'];
          return {'title': chapterTitle, 'link': chapterLink};
        }).toList();

        final author = element
            .querySelectorAll('span')[0]
            .text
            .replaceAll('Author(s) : ', '')
            .trim();
        final updated = element
            .querySelectorAll('span')[1]
            .text
            .replaceAll('Updated : ', '')
            .trim();
        final views = element
            .querySelectorAll('span')[2]
            .text
            .replaceAll('View : ', '')
            .trim();

        mangaList.add({
          'id': link?.split('/')[3],
          'title': title,
          'link': link,
          'image': image,
          'chapters': chapters,
          'author': author,
          'updated': updated,
          'views': views,
        });
      });
      log(mangaList.toString());
      return mangaList;
    } else {
      throw Exception('Failed to load manga search results');
    }
  }

  Future<dynamic> mapToAnilist(String id, {int page = 1}) async {
    final mangaList = await fetchMangaSearchResults(id);
    String bestMatchId = findBestMatch(id, mangaList);
    if (bestMatchId.isNotEmpty) {
      return await fetchMangaChapters(bestMatchId);
    } else {
      throw Exception('No suitable match found for the query');
    }
  }
}
