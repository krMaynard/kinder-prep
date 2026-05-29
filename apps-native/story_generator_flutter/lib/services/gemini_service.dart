import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/story.dart';

const _textModel = 'gemini-3.1-pro-preview';
const _imageModel = 'gemini-3.1-flash-image';
const _apiBase = 'https://generativelanguage.googleapis.com/v1beta';

const Map<String, Map<String, String>> _genderPronouns = {
  'girl': {'subject': 'she', 'object': 'her', 'possessive': 'her'},
  'boy': {'subject': 'he', 'object': 'him', 'possessive': 'his'},
  'child': {'subject': 'they', 'object': 'them', 'possessive': 'their'},
};

const Map<String, String> _genderDescriptors = {
  'girl': 'a 4-year-old girl',
  'boy': 'a 4-year-old boy',
  'child': 'a 4-year-old child',
};

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
    String gender = 'child',
  }) async {
    final sightWordsStr =
        sightWords.isNotEmpty ? sightWords.join(', ') : 'the, a, is, can, I, see, go';
    final pronouns = _genderPronouns[gender] ?? _genderPronouns['child']!;
    final descriptor = _genderDescriptors[gender] ?? _genderDescriptors['child']!;

    final prompt = '''You are writing a decodable book for a 4-year-old learning to read.

Child: $childName ($descriptor)
Hero of the story: $childName and $favoriteCharacter
Pronouns for $childName: ${pronouns['subject']}/${pronouns['object']}/${pronouns['possessive']} — use these consistently.
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
        final candidates = body['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('No candidates in Gemini response: ${response.body}');
        }
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts == null) {
          throw Exception('No content parts in Gemini response: ${response.body}');
        }
        final buffer = StringBuffer();
        for (final part in parts) {
          if (part is Map<String, dynamic>) {
            final text = part['text'];
            if (text is String) buffer.write(text);
          }
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
    String gender = 'child',
    List<int>? referencePhotoBytes,
    String? referencePhotoMimeType,
  }) async {
    final descriptor =
        (_genderDescriptors[gender] ?? _genderDescriptors['child']!).replaceFirst('a ', 'a friendly ');

    var prompt = 'Children\'s book illustration. $pageText '
        'Characters: $childName ($descriptor) and $favoriteCharacter. '
        'Style: $styleGuide '
        'No text, no letters, no signs in the image. '
        'Page $pageNum of $pageCount.';

    final hasPhoto = referencePhotoBytes != null &&
        referencePhotoBytes.isNotEmpty &&
        referencePhotoMimeType != null &&
        referencePhotoMimeType.isNotEmpty;

    if (hasPhoto) {
      prompt = 'The attached photo shows the real child. Use it as a reference for '
          "$childName's face, hair, and skin tone, but always render the child "
          'in the chosen illustration style — do not copy the photo directly. '
          '$prompt';
    }

    final List<Map<String, dynamic>> parts = [
      {'text': prompt},
    ];
    if (hasPhoto) {
      parts.add({
        'inlineData': {
          'mimeType': referencePhotoMimeType,
          'data': base64Encode(referencePhotoBytes),
        }
      });
    }

    final url = Uri.parse('$_apiBase/models/$_imageModel:generateContent?key=$apiKey');

    Exception? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {'parts': parts}
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
        final candidates = body['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('No candidates in Gemini response: ${response.body}');
        }
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final responseParts = content?['parts'] as List<dynamic>?;
        if (responseParts == null) {
          throw Exception('No content parts in Gemini response: ${response.body}');
        }
        for (final part in responseParts) {
          if (part is! Map<String, dynamic>) continue;
          final inlineData = part['inlineData'];
          if (inlineData is Map<String, dynamic>) {
            final mimeType = inlineData['mimeType'];
            final data = inlineData['data'];
            if (mimeType is String && mimeType.startsWith('image/') && data is String) {
              return base64Decode(data);
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
