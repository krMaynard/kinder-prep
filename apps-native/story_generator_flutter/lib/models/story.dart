class StoryPage {
  final int page;
  String text;
  List<String> vocabViolations;

  StoryPage({required this.page, required this.text, this.vocabViolations = const []});

  factory StoryPage.fromJson(Map<String, dynamic> json) => StoryPage(
        page: json['page'] as int,
        text: json['text'] as String,
      );

  Map<String, dynamic> toJson() => {'page': page, 'text': text};

  StoryPage copyWith({String? text, List<String>? vocabViolations}) => StoryPage(
        page: page,
        text: text ?? this.text,
        vocabViolations: vocabViolations ?? this.vocabViolations,
      );
}

class Story {
  final String title;
  final List<StoryPage> pages;

  const Story({required this.title, required this.pages});

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        title: json['title'] as String? ?? 'My Story',
        pages: (json['pages'] as List<dynamic>)
            .map((p) => StoryPage.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
