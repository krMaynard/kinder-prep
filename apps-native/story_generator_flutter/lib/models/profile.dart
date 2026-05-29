const List<String> kGenders = ['girl', 'boy', 'child'];

class Profile {
  String childName;
  String favoriteCharacter;
  String phonicsLevel;
  String gender;

  Profile({
    this.childName = '',
    this.favoriteCharacter = '',
    this.phonicsLevel = 'CVC short-a',
    this.gender = 'child',
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        childName: json['childName'] as String? ?? '',
        favoriteCharacter: json['favoriteCharacter'] as String? ?? '',
        phonicsLevel: json['phonicsLevel'] as String? ?? 'CVC short-a',
        gender: json['gender'] as String? ?? 'child',
      );

  Map<String, dynamic> toJson() => {
        'childName': childName,
        'favoriteCharacter': favoriteCharacter,
        'phonicsLevel': phonicsLevel,
        'gender': gender,
      };

  Profile copyWith({
    String? childName,
    String? favoriteCharacter,
    String? phonicsLevel,
    String? gender,
  }) =>
      Profile(
        childName: childName ?? this.childName,
        favoriteCharacter: favoriteCharacter ?? this.favoriteCharacter,
        phonicsLevel: phonicsLevel ?? this.phonicsLevel,
        gender: gender ?? this.gender,
      );
}
