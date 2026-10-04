class School {
  final String id;
  final String name;
  final String? imageUrl;
  final int memberCount;

  School({required this.id, required this.name, this.imageUrl, this.memberCount = 0});

  factory School.fromMap(String id, Map<String, dynamic> data) {
    return School(
      id: id,
      name: data['name']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString(),
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
    };
  }
}