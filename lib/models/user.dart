class AppUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? joinedSchoolId;
  final int points;
  final List<String> savedPosts;
  final List<String> likedPosts;
  final String? profilePic;
  final int actions;
  final int streak;
  final int weekPoints;
  final int weekGoal;

  AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.joinedSchoolId,
    required this.points,
    required this.savedPosts,
    required this.likedPosts,
    this.profilePic,
    required this.actions,
    required this.streak,
    required this.weekPoints,
    required this.weekGoal,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get displayName => firstName;

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {

    String firstName = '';
    String lastName = '';

    if (data['firstName'] != null && data['lastName'] != null) {

      firstName = data['firstName'] ?? '';
      lastName = data['lastName'] ?? '';
    } else if (data['name'] != null) {

      final nameParts = (data['name'] as String).trim().split(' ');
      firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    return AppUser(
      id: id,
      firstName: firstName,
      lastName: lastName,
      joinedSchoolId: data['joinedSchoolId'],
      points: (data['points'] as num?)?.toInt() ?? 0,
      savedPosts: List<String>.from(data['savedPosts'] ?? []),
      likedPosts: List<String>.from(data['likedPosts'] ?? []),
      profilePic: data['profilePic'],
      actions: (data['actions'] as num?)?.toInt() ?? 0,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      weekPoints: (data['weekPoints'] as num?)?.toInt() ?? 0,
      weekGoal: (data['weekGoal'] as num?)?.toInt() ?? 800,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'joinedSchoolId': joinedSchoolId,
      'points': points,
      'savedPosts': savedPosts,
      'likedPosts': likedPosts,
      'profilePic': profilePic,
      'actions': actions,
      'streak': streak,
      'weekPoints': weekPoints,
      'weekGoal': weekGoal,
    };
  }

  AppUser copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? joinedSchoolId,
    int? points,
    List<String>? savedPosts,
    List<String>? likedPosts,
    String? profilePic,
    int? actions,
    int? streak,
    int? weekPoints,
    int? weekGoal,
  }) {
    return AppUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      joinedSchoolId: joinedSchoolId ?? this.joinedSchoolId,
      points: points ?? this.points,
      savedPosts: savedPosts ?? this.savedPosts,
      likedPosts: likedPosts ?? this.likedPosts,
      profilePic: profilePic ?? this.profilePic,
      actions: actions ?? this.actions,
      streak: streak ?? this.streak,
      weekPoints: weekPoints ?? this.weekPoints,
      weekGoal: weekGoal ?? this.weekGoal,
    );
  }
}