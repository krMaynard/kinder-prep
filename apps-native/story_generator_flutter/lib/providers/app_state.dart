import 'package:flutter/foundation.dart';

import '../models/profile.dart';
import '../models/story.dart';
import '../models/style_template.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/vocab_service.dart';

enum GenerationStatus { idle, generatingText, generatingImages, done, error }

class AppState extends ChangeNotifier {
  final _storage = StorageService();
  final _gemini = GeminiService();

  // Profile & config
  Profile profile = Profile();
  String apiKey = '';
  bool rememberKey = false;
  String styleGuide = kDefaultStyleGuide;
  Map<String, String> styleTemplates = {...kBuiltinTemplates};

  // Story spec
  String theme = '';
  String storyCharacterOverride = '';
  String sightWordsRaw = '';
  int pageCount = 6;

  // Reference photo of the main character (transient — not persisted)
  List<int>? referencePhotoBytes;
  String? referencePhotoMimeType;
  String? referencePhotoName;

  // Generated content
  Story? story;
  Map<int, List<int>> pageImages = {}; // page number → PNG bytes

  // UI state
  GenerationStatus status = GenerationStatus.idle;
  String statusMessage = '';
  String? errorMessage;

  int get imagesGenerated => pageImages.length;
  int get totalPages => story?.pages.length ?? 0;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    profile = await _storage.loadProfile();
    apiKey = await _storage.loadApiKey() ?? '';
    rememberKey = await _storage.isRememberKey();
    styleGuide = await _storage.loadStyleGuide();
    styleTemplates = await _storage.loadAllTemplates();
    storyCharacterOverride = profile.favoriteCharacter;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Profile & settings
  // ---------------------------------------------------------------------------

  Future<void> saveProfile(Profile updated) async {
    profile = updated;
    await _storage.saveProfile(updated);
    notifyListeners();
  }

  Future<void> updateApiKey(String key, {required bool remember}) async {
    apiKey = key;
    rememberKey = remember;
    if (remember && key.isNotEmpty) {
      await _storage.saveApiKey(key);
    } else {
      await _storage.setRememberKey(false);
    }
    notifyListeners();
  }

  Future<void> saveStyleGuide(String guide) async {
    styleGuide = guide;
    await _storage.saveStyleGuide(guide);
    notifyListeners();
  }

  Future<void> saveUserTemplate(String name, String text) async {
    final user = await _storage.loadUserTemplates();
    user[name] = text;
    await _storage.saveUserTemplates(user);
    styleTemplates = await _storage.loadAllTemplates();
    notifyListeners();
  }

  Future<void> deleteUserTemplate(String name) async {
    final user = await _storage.loadUserTemplates();
    user.remove(name);
    await _storage.saveUserTemplates(user);
    styleTemplates = await _storage.loadAllTemplates();
    notifyListeners();
  }

  void setReferencePhoto({
    required List<int> bytes,
    required String mimeType,
    required String name,
  }) {
    referencePhotoBytes = bytes;
    referencePhotoMimeType = mimeType;
    referencePhotoName = name;
    notifyListeners();
  }

  void clearReferencePhoto() {
    referencePhotoBytes = null;
    referencePhotoMimeType = null;
    referencePhotoName = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Story generation
  // ---------------------------------------------------------------------------

  Future<void> generateStory() async {
    if (apiKey.isEmpty) {
      errorMessage = 'Please enter your Gemini API key.';
      notifyListeners();
      return;
    }
    if (profile.childName.isEmpty) {
      errorMessage = "Please enter the child's name.";
      notifyListeners();
      return;
    }
    if (theme.isEmpty) {
      errorMessage = 'Please enter a story theme.';
      notifyListeners();
      return;
    }

    story = null;
    pageImages = {};
    errorMessage = null;
    status = GenerationStatus.generatingText;
    statusMessage = 'Generating story text…';
    notifyListeners();

    try {
      final sightList = sightWordsRaw
          .split(',')
          .map((w) => w.trim())
          .where((w) => w.isNotEmpty)
          .toList();

      final generated = await _gemini.generateStoryText(
        apiKey: apiKey,
        childName: profile.childName,
        favoriteCharacter: storyCharacterOverride.isNotEmpty
            ? storyCharacterOverride
            : profile.favoriteCharacter,
        theme: theme,
        phonicsLevel: profile.phonicsLevel,
        sightWords: sightList,
        pageCount: pageCount,
        gender: profile.gender,
      );

      // Run vocabulary check on each page
      final extraAllowed = <String>[
        ...profile.childName.split(' '),
        ...(storyCharacterOverride.isNotEmpty
                ? storyCharacterOverride
                : profile.favoriteCharacter)
            .split(' '),
        ...sightList,
      ].where((w) => w.isNotEmpty).toList();

      final checkedPages = generated.pages.map((p) {
        final violations = checkVocabulary(p.text, profile.phonicsLevel, extraAllowed);
        return p.copyWith(vocabViolations: violations);
      }).toList();

      story = Story(title: generated.title, pages: checkedPages);
      status = GenerationStatus.done;
      statusMessage = 'Story generated — ${story!.pages.length} pages.';
    } catch (e) {
      status = GenerationStatus.error;
      errorMessage = e.toString();
      statusMessage = 'Text generation failed.';
    }
    notifyListeners();
  }

  Future<void> generateAllImages() async {
    if (story == null || apiKey.isEmpty) return;

    status = GenerationStatus.generatingImages;
    final pages = story!.pages;
    final char = storyCharacterOverride.isNotEmpty
        ? storyCharacterOverride
        : profile.favoriteCharacter;

    for (final page in pages) {
      statusMessage = 'Generating image for page ${page.page} of ${pages.length}…';
      notifyListeners();
      try {
        final bytes = await _gemini.generatePageImage(
          apiKey: apiKey,
          pageText: page.text,
          childName: profile.childName,
          favoriteCharacter: char,
          pageNum: page.page,
          pageCount: pages.length,
          styleGuide: styleGuide,
          gender: profile.gender,
          referencePhotoBytes: referencePhotoBytes,
          referencePhotoMimeType: referencePhotoMimeType,
        );
        pageImages[page.page] = bytes;
        notifyListeners();
      } catch (e) {
        // Log and continue — partial failure is acceptable
        debugPrint('Image gen failed for page ${page.page}: $e');
      }
    }

    status = GenerationStatus.done;
    statusMessage = 'All images generated.';
    notifyListeners();
  }

  Future<void> regeneratePageImage(int pageNum, String pageText) async {
    if (apiKey.isEmpty) return;
    final char = storyCharacterOverride.isNotEmpty
        ? storyCharacterOverride
        : profile.favoriteCharacter;

    statusMessage = 'Regenerating image for page $pageNum…';
    notifyListeners();
    try {
      final bytes = await _gemini.generatePageImage(
        apiKey: apiKey,
        pageText: pageText,
        childName: profile.childName,
        favoriteCharacter: char,
        pageNum: pageNum,
        pageCount: story?.pages.length ?? 1,
        styleGuide: styleGuide,
        gender: profile.gender,
        referencePhotoBytes: referencePhotoBytes,
        referencePhotoMimeType: referencePhotoMimeType,
      );
      pageImages[pageNum] = bytes;
      statusMessage = 'Page $pageNum image updated.';
    } catch (e) {
      statusMessage = 'Image regeneration failed: $e';
    }
    notifyListeners();
  }

  void updatePageText(int pageNum, String newText) {
    if (story == null) return;
    final sightList = sightWordsRaw
        .split(',')
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
    final extraAllowed = <String>[
      ...profile.childName.split(' '),
      ...(storyCharacterOverride.isNotEmpty
              ? storyCharacterOverride
              : profile.favoriteCharacter)
          .split(' '),
      ...sightList,
    ].where((w) => w.isNotEmpty).toList();

    final violations = checkVocabulary(newText, profile.phonicsLevel, extraAllowed);
    final updatedPages = story!.pages.map((p) {
      if (p.page == pageNum) return p.copyWith(text: newText, vocabViolations: violations);
      return p;
    }).toList();
    story = Story(title: story!.title, pages: updatedPages);
    notifyListeners();
  }

  void resetStory() {
    story = null;
    pageImages = {};
    status = GenerationStatus.idle;
    statusMessage = '';
    errorMessage = null;
    notifyListeners();
  }
}
