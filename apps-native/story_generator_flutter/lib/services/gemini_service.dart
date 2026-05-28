import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/story.dart';

const _textModel = 'gemini-3.1-pro-preview';
const _imageModel = 'gemini-3.1-flash-image';
const _apiBase = 'https://generativelanguage.googleapis.com/v1beta';

class GeminiService {
  // ---------------------------------------------------------------------------
  // Story text generation
  // ---------------------------------------------------------------------------

  Future<Story> generateStoryText({
    required String apiKey,
    required String childName,
    required String favoriteCharacter,
    required String theme,
    required String phonicsLevel,
    required List<String> sightWords,
    required int pageCount,
  }) async {
    final sightWordsStr =
        sightWords.isNotEmpty ? sightWords.join(', ') : 'the, a, is, can, I, see, go';

    final prompt = '''You are writing a decodable book for a 4-year-old learning to read.

Child: $childName
Hero of the story: $childName and $favoriteCharacter
Theme: $theme
Pages: $pageCount (one sentence per page, 6-8 words max per sentence)

STRICT vocabulary rules:
- Phonics level: $phonicsLevel — only use words decodable at this level
- Allowed sight words: $sightWordsStr
- Every other word must follow the phonics pattern exactly
- NO multi-syllable words except the character name

Output format — return ONLY valid JSON, no markdown, no code fences:
{
  "title": "...",
  "pages": [
    {"page": 1, "text": "..."},
    ...
  ]
}''';

    final url = Uri.parse('$_apiBase/models/$_textModel:generateContent?key=$apiKey');

    Exception? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Text API error ${response.statusCode}: ${response.body}');
        }

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final parts = (body['candidates'] as List<dynamic>)[0]['content']['parts']
            as List<dynamic>;
        final buffer = StringBuffer();
        for (final part in parts) {
          final text = (part as Map<String, dynamic>)['text'];
          if (text is String) buffer.write(text);
        }
        var raw = buffer.toString().trim();
        raw = raw.replaceAll(RegExp(r'^```[a-z]*\n?', multiLine: true), '');
        raw = raw.replaceAll(RegExp(r'\n?```$', multiLine: true), '');
        return Story.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on FormatException catch (e) {
        lastError = e;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (attempt == 0) continue;
        break;
      }
    }
    throw Exception('Story text generation failed: $lastError');
  }

  // ---------------------------------------------------------------------------
  // Page image generation
  // ---------------------------------------------------------------------------

  Future<List<int>> generatePageImage({
    required String apiKey,
    required String pageText,
    required String childName,
    required String favoriteCharacter,
    required int pageNum,
    required int pageCount,
    required String styleGuide,
  }) async {
    final prompt = 'Children\'s book illustration. $pageText '
        'Characters: $childName (a friendly 4-year-old child) and $favoriteCharacter. '
        'Style: $styleGuide '
        'No text, no letters, no signs in the image. '
        'Page $pageNum of $pageCount.';

    final url = Uri.parse('$_apiBase/models/$_imageModel:generateContent?key=$apiKey');

    Exception? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'responseModalities': ['IMAGE', 'TEXT'],
            },
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Image API error ${response.statusCode}: ${response.body}');
        }

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final parts = (body['candidates'] as List<dynamic>)[0]['content']['parts']
            as List<dynamic>;
        for (final part in parts) {
          final inlineData = (part as Map<String, dynamic>)['inlineData'];
          if (inlineData != null) {
            final mimeType = inlineData['mimeType'] as String;
            if (mimeType.startsWith('image/')) {
              return base64Decode(inlineData['data'] as String);
            }
          }
        }
        throw Exception('No image data in API response');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (attempt == 0) continue;
        break;
      }
    }
    throw Exception('Image generation failed for page $pageNum: $lastError');
  }
}
