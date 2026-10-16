class Book {
  final String id;
  final String title;
  final String author;
  final String fileName; // файл внутри папки books/
  final String? coverFileName; // обложка, если есть
  final DateTime addedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.fileName,
    this.coverFileName,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'fileName': fileName,
    'coverFileName': coverFileName,
    'addedAt': addedAt.toIso8601String(),
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    fileName: json['fileName'] as String,
    coverFileName: json['coverFileName'] as String?,
    addedAt: DateTime.parse(json['addedAt'] as String),
  );
}
