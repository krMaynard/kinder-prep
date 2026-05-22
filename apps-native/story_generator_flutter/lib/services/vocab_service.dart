// Port of the Python check_vocabulary function and phonics word sets.

const List<String> kPhonicsLevels = [
  'CVC short-a',
  'CVC short-i',
  'CVC short-o',
  'CVC short-u',
  'CVC short-e',
  'CVCC',
  'Long vowel (silent-e)',
  'Digraphs',
];

const Map<String, Set<String>> kPhonicsWordSets = {
  'CVC short-a': {
    'can', 'cat', 'bat', 'hat', 'mat', 'rat', 'sat', 'fat', 'pat',
    'man', 'pan', 'ran', 'tan', 'van', 'ban', 'fan',
    'bad', 'dad', 'had', 'mad', 'sad', 'lad', 'add',
    'bag', 'rag', 'tag', 'wag', 'nag', 'lag',
    'cap', 'map', 'nap', 'rap', 'tap', 'zap', 'gap',
    'car', 'bar', 'far', 'jar', 'tar',
    'has', 'was', 'as', 'at', 'am', 'an', 'and', 'ask',
  },
  'CVC short-i': {
    'bit', 'fit', 'hit', 'kit', 'lit', 'pit', 'sit', 'wit',
    'big', 'dig', 'fig', 'jig', 'pig', 'rig', 'wig',
    'bid', 'did', 'hid', 'kid', 'lid', 'rid',
    'bin', 'fin', 'pin', 'sin', 'tin', 'win',
    'dip', 'hip', 'lip', 'nip', 'rip', 'sip', 'tip', 'zip',
    'his', 'is', 'in', 'if', 'it', 'its', 'him', 'six', 'mix', 'fix',
  },
  'CVC short-o': {
    'bob', 'cob', 'job', 'mob', 'rob', 'sob',
    'cod', 'god', 'nod', 'pod', 'rod',
    'bog', 'cog', 'dog', 'fog', 'hog', 'jog', 'log',
    'cop', 'hop', 'mop', 'pop', 'top',
    'cot', 'dot', 'got', 'hot', 'jot', 'lot', 'not', 'pot', 'rot',
    'on', 'of', 'or', 'off', 'odd', 'box', 'fox',
  },
  'CVC short-u': {
    'bud', 'mud',
    'bug', 'dug', 'hug', 'jug', 'mug', 'rug', 'tug',
    'bun', 'fun', 'gun', 'run', 'sun',
    'bus', 'but', 'cut', 'gut', 'hut', 'nut', 'put', 'rut',
    'cub', 'hub', 'rub', 'sub', 'tub', 'cup', 'pup',
    'up', 'us',
  },
  'CVC short-e': {
    'bed', 'fed', 'led', 'red', 'wed',
    'beg', 'keg', 'leg', 'peg',
    'den', 'hen', 'men', 'pen', 'ten',
    'jet', 'let', 'met', 'net', 'pet', 'set', 'vet', 'wet', 'yet', 'yes', 'get',
    'belt', 'felt', 'melt', 'held', 'help', 'self',
  },
  'CVCC': {
    'band', 'hand', 'land', 'sand', 'best', 'nest', 'rest', 'test',
    'bold', 'cold', 'fold', 'gold', 'hold', 'told',
    'bump', 'dump', 'jump', 'pump',
    'back', 'jack', 'lack', 'pack', 'rack', 'sack',
    'lick', 'kick', 'pick', 'sick', 'tick',
    'dock', 'lock', 'rock', 'sock',
    'duck', 'luck', 'muck', 'suck', 'tuck',
    'fill', 'hill', 'mill', 'will', 'pill', 'till',
    'bell', 'cell', 'fell', 'sell', 'tell', 'well', 'yell',
    'full', 'pull', 'bull',
    'fast', 'last', 'mast', 'past', 'fist', 'list', 'mist',
  },
  'Long vowel (silent-e)': {
    'bake', 'cake', 'fake', 'lake', 'make', 'rake', 'take',
    'bike', 'hike', 'like',
    'bone', 'cone', 'tone', 'zone', 'lone',
    'cute', 'mule', 'rule', 'tune',
    'came', 'game', 'name', 'same', 'tame', 'fame',
    'time', 'dime', 'lime', 'rhyme',
    'home', 'dome', 'use', 'fuse',
    'side', 'hide', 'ride', 'wide',
    'safe', 'wave', 'cave', 'gave', 'life', 'wife',
  },
  'Digraphs': {
    'ship', 'shop', 'shed', 'shot', 'shut', 'shin',
    'chip', 'chap', 'chin', 'chop', 'chat', 'check',
    'that', 'this', 'them', 'then', 'than', 'with',
    'when', 'whip',
    'path', 'math', 'bath', 'both',
    'much', 'such', 'rich', 'inch',
    'wish', 'fish', 'dish',
    'ring', 'king', 'wing', 'song', 'long', 'hang',
    'phone', 'graph',
  },
};

const Set<String> kCommonSightWords = {
  'the', 'a', 'an', 'is', 'are', 'was', 'were',
  'i', 'me', 'my', 'we', 'us', 'our',
  'he', 'she', 'it', 'they', 'his', 'her', 'its',
  'you', 'your',
  'to', 'do', 'go', 'so', 'no',
  'and', 'or', 'but', 'for', 'of', 'in', 'on', 'at', 'by',
  'up', 'out', 'off', 'all', 'one', 'two', 'too', 'has',
  'have', 'had', 'not', 'be', 'been', 'can', 'will', 'said',
  'see', 'look', 'come', 'like', 'play', 'went', 'what',
  'here', 'there', 'where', 'who', 'how',
  'with', 'from', 'into', 'over', 'down', 'now',
  'then', 'when', 'that', 'this',
  'big', 'little', 'old', 'new', 'good',
  'some', 'day', 'way', 'time',
};

/// Returns the list of words in [text] that exceed [phonicsLevel].
/// [extraAllowed] contains child name, character name, and custom sight words.
List<String> checkVocabulary(
  String text,
  String phonicsLevel,
  List<String> extraAllowed,
) {
  final allowed = <String>{
    ...kCommonSightWords,
    ...?kPhonicsWordSets[phonicsLevel],
    ...extraAllowed.map((w) => w.toLowerCase().trim()),
  };

  final tokens = RegExp(r"[a-zA-Z']+").allMatches(text).map((m) => m.group(0)!);
  final violations = <String>[];

  for (final token in tokens) {
    final word = token.toLowerCase().replaceAll(RegExp(r"^'+|'+$"), '');
    if (word.length <= 1) continue;
    if (!allowed.contains(word)) violations.add(token);
  }
  return violations;
}
