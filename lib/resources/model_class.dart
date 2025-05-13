class ModelCpp {
  final int id;
  final String filename;
  final String title;
  final List<ContentSection> content;

  ModelCpp({required this.id, required this.filename, required this.title, required this.content});

  factory ModelCpp.fromJson(Map<String, dynamic> json, int id, String filename) {
    try {
      var contentList = json['content'] as List? ?? []; // Handle null case
      List<ContentSection> contentSection =
      contentList.map((c) => ContentSection.fromJson(c)).toList();

      return ModelCpp(
        id: id,
        filename: filename,
        title: json['title'] ?? "Untitled", // Default title if missing
        content: contentSection,
      );
    } catch (e) {
      throw Exception("Error parsing ModelCpp JSON: $e");
    }
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'filename': filename,
      'title': title,
      'content': content.map((c) => c.toJson()).toList(),
    };
  }
}

class ContentSection {
  final String heading;
  final List<String> paragraphs;

  ContentSection({required this.heading, required this.paragraphs});

  factory ContentSection.fromJson(Map<String, dynamic> json) {
    try {
      return ContentSection(
        heading: json['heading'] ?? "No Heading",
        paragraphs: List<String>.from(json['paragraphs'] ?? []),
      );
    } catch (e) {
      throw Exception("Error parsing ContentSection JSON: $e");
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'heading': heading,
      'paragraphs': paragraphs,
    };
  }
}
