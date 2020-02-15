class Household {
  final String id;
  final String name;

  Household(this.id, this.name);

  Household.fromMap(Map<String, dynamic> map) : this(map['id'], map['name']);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  @override
  String toString() => toMap().toString();
}

class Tonie {
  final String id;
  final String name;
  final List<Chapter> chapters;

  Tonie(this.id, this.name, this.chapters);

  Tonie.fromMap(Map<String, dynamic> map)
      : this(
            map['id'],
            map['name'],
            (map['chapters'] as List)
                .map((item) => Chapter.fromMap(item))
                .toList());

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'chapters': chapters.map((c) => c.toMap()).toList()
      };

  @override
  String toString() => toMap().toString();
}

class Chapter {
  final String id;
  final String title;
  final String file;
  final double seconds;
  final bool transcoding;

  Chapter(this.id, this.title, this.file, this.seconds, this.transcoding);

  Chapter.fromMap(Map<String, dynamic> map)
      : this(map['id'], map['title'], map['file'], map['seconds'],
            map['transcoding']);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'file': file,
        'seconds': seconds,
        'transcoding': transcoding
      };

  @override
  String toString() => toMap().toString();
}
