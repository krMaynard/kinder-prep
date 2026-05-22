class Profile {
  String childName;
  String favoriteCharacter;
  String phonicsLevel;

  Profile({
    this.childName = '',
    this.favoriteCharacter = '',
    this.phonicsLevel = 'CVC short-a',
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        childName: json['childName'] as String? ?? '',
        favoriteCharacter: json['favoriteCharacter'] as String? ?? '',
        phonicsLevel: json['phonicsLevel'] as String? ?? 'CVC short-a',
      );

  Map<String, dynamic> toJson() => {
        'childName': childName,
        'favoriteCharacter': favoriteCharacter,
        'phonicsLevel': phonicsLevel,
      };

  Profile copyWith({
    String? childName,
    String? favoriteCharacter,
    String? phonicsLevel,
  }) =>
      Profile(
        childName: childName ?? this.childName,
        favoriteCharacter: favoriteCharacter ?? this.favoriteCharacter,
        phonicsLevel: phonicsLevel ?? this.phonicsLevel,
      );
}
