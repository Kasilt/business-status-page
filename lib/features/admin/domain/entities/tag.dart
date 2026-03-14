class Tag {
  final String id;
  final String label;
  final String color;

  Tag({
    required this.id,
    required this.label,
    required this.color,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      label: json['label'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'color': color,
    };
  }
}
