// ignore_for_file: empty_c
import 'dart:developer';

import 'package:aurora/utils/scrapers/manga/helper/jaro_helper.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

const urlLink = "https://ww8.mangakakalot.tv";

class MangaKakalotUnofficial {
  Future<dynamic> fetchMangaChapters(String mangaId) async {
    try {
      final response = await http.get(Uri.parse('$urlLink/manga/$mangaId'));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        final target = document.querySelector('.manga-info-top');

        final imageUrl =
            "https://www.mangakakalot.com${target?.querySelector('.manga-info-pic img')?.attributes['src'] ?? ''}";
        final name = target?.querySelector('h1')?.text.trim() ?? '';
        final alternativeTitle =
            target?.querySelector('.story-alternative')?.text.trim() ?? '';

        final authors = target
            ?.querySelectorAll('.manga-info-text li')[1]
            .querySelectorAll('a')
            .map((e) => e.text.trim())
            .toList();

        final status = target
                ?.querySelectorAll('.manga-info-text li')[2]
                .text
                .split(":")[1]
                .trim() ??
            'Unknown';
        final updated = target
                ?.querySelectorAll('.manga-info-text li')[3]
                .text
                .split(":")[1]
                .trim() ??
            'Unknown';
        final view = target
                ?.querySelectorAll('.manga-info-text li')[5]
                .text
                .split(":")[1]
                .trim() ??
            'Unknown';

        final genresRaw = target
                ?.querySelectorAll('.manga-info-text li')[6]
                .text
                .split(":")[1]
                .trim() ??
            '';
        final genres = genresRaw
            .split(",")
            .map((val) => val.trim())
            .where((val) => val.isNotEmpty)
            .toList();

        final descriptionElement = document.querySelector('#noidungm');
        final description =
            descriptionElement?.text.split('summary:').last.trim() ?? '';

        final chapters = <Map<String, String>>[];
        final chapterList = document.querySelector('.chapter-list');
        if (chapterList != null) {
          final chapterElements = chapterList.querySelectorAll('.row');
          for (var chapterElement in chapterElements) {
            final chapterNumber = chapterElement
                    .querySelector('a')
                    ?.attributes['href']
                    ?.split('/')
                    .last
                    .split('-')
                    .last ??
                '';
            final chapterTitle =
                chapterElement.querySelector('a')?.text.trim() ?? '';
            final chapterUrl =
                chapterElement.querySelector('a')?.attributes['href'] ?? '';
            final chapterViews =
                chapterElement.querySelectorAll('span')[1].text.trim();
            final chapterDate =
                chapterElement.querySelectorAll('span')[2].text.trim();

            chapters.add({
              'title': chapterTitle,
              'path': chapterUrl,
              'views': chapterViews,
              'date': chapterDate,
              'number': chapterNumber,
            });
          }
        }

        final metaData = {
          'id': mangaId,
          'imageUrl': imageUrl,
          'name': name,
          'alternativeTitle': alternativeTitle,
          'authors': authors,
          'status': status,
          'updated': updated,
          'view': view,
          'genres': genres,
          'description': description,
          'chapterList': chapters.reversed.toList(),
        };
        return metaData;
      } else {
        log('Failed to load manga details, status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error: $e');
    }
  }

  Future<dynamic> fetchChapterImages(
      {required String mangaId, required String chapterId}) async {
    final url = 'https://ww8.mangakakalot.tv/chapter/$mangaId/$chapterId';
    int index = 0;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final target = document.querySelector('.trang-doc');

        final title = document
            .querySelector('body > div.info-top-chapter > h2')
            ?.text
            .split('Chapter')
            .first
            .trim();
        final currentChapter =
            ('Chapter${document.querySelector('body > div.info-top-chapter > h2')?.text.split('Chapter').last}');

        final chapterListIds =
            target?.querySelectorAll('#c_chapter option').map((option) {
                  return {
                    'id': option.attributes['value'] ?? '',
                    'name': option.text.trim(),
                  };
                }).toList() ??
                [];

        final images = target?.querySelectorAll('.vung-doc img').map((img) {
              index++;
              return {
                'title': img.attributes['title'] ?? '',
                'image': img.attributes['data-src'] ?? '',
              };
            }).toList() ??
            [];

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

  Future<dynamic> fetchMangaSearchResults(String id, {int page = 1}) async {
    final String query = "$id?page=$page";
    final String url = "$urlLink/search/$query";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final List<Map<String, String>> mangaList = [];

        document
            .querySelectorAll(".panel_story_list .story_item")
            .asMap()
            .forEach((index, element) {
          final target = element;
          final id = target
              .querySelector("a:first-child")
              ?.attributes['href']
              ?.split("/")[2]
              .trim();
          final image =
              target.querySelector("a:first-child img")?.attributes['src'];
          final title = target.querySelector("h3 a")?.text;

          if (id != null && image != null && title != null) {
            mangaList.add({
              'id': id,
              'image': image,
              'title': title,
            });
          }
        });
        log(mangaList.toString());
        return {
          'mangaList': mangaList,
          'metaData': {},
        };
      } else {
        throw Exception('Failed to load manga');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<dynamic> mapToAnilist(String id, {int page = 1}) async {
    final mangaList = await fetchMangaSearchResults(id);
    String bestMatchId = findBestMatch(id, mangaList['mangaList']);
    if (bestMatchId.isNotEmpty) {
      return await fetchMangaChapters(bestMatchId);
    } else {
      throw Exception('No suitable match found for the query');
    }
  }
}
