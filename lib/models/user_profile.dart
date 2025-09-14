class UserProfile {
  final String name;
  final int age;
  final String? photoPath;
  final String? photoUrl;
  final Map<String, double> skills;
  final Map<String, double> averageSkills;
  final bool isGoalkeeper;
  final bool profileCompleted;

  UserProfile({
    this.name = '',
    this.age = 30,
    this.photoPath,
    this.photoUrl,
    Map<String, double>? skills,
    Map<String, double>? averageSkills,
    this.isGoalkeeper = false,
    this.profileCompleted = false,
  }) : skills = skills ?? {
          'velocidad': 50.0,
          'resistencia': 50.0,
          'tiro': 50.0,
          'gambeta': 50.0,
          'pases': 50.0,
        },
        averageSkills = averageSkills ?? {
          'velocidad': 0.0,
          'resistencia': 0.0,
          'tiro': 0.0,
          'gambeta': 0.0,
          'pases': 0.0,
        };

  UserProfile copyWith({
    String? name,
    int? age,
    String? photoPath,
    String? photoUrl,
    Map<String, double>? skills,
    Map<String, double>? averageSkills,
    bool? isGoalkeeper,
    bool? profileCompleted,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      skills: skills ?? this.skills,
      averageSkills: averageSkills ?? this.averageSkills,
      isGoalkeeper: isGoalkeeper ?? this.isGoalkeeper,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'photo_path': photoPath,
      'photo_url': photoUrl,
      'skills': skills,
      'average_skills': averageSkills,
      'is_goalkeeper': isGoalkeeper,
      'profile_completed': profileCompleted,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      age: json['age'] ?? 30,
      photoPath: json['photo_path'],
      photoUrl: json['photo_url'],
      skills: Map<String, double>.from(json['skills'] ?? {}),
      averageSkills: Map<String, double>.from(json['average_skills'] ?? {}),
      isGoalkeeper: json['is_goalkeeper'] ?? false,
      profileCompleted: json['profile_completed'] ?? false,
    );
  }
}