class GroupModel {
  final String id;
  final String name;
  final String createdBy;
  final List<String> members;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'created_by': createdBy,
      'members': members,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      createdBy: map['created_by'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
