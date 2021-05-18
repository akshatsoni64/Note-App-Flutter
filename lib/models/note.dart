class Note {
  final String id;
  final String title;
  final List<String> labels;
  final String text;

  Note(this.id, this.title, this.labels, this.text);

  Note.fromJson(Map<String, dynamic> json):
        id = json['id'],
        title = json['title'],
        labels = json['labels'],
        text = json['text'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'labels': labels,
    'text': text
  };
}