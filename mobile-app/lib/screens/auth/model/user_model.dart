class UserModel {
  final String? id;
  final String phone;
  final String? name;
  final String? classNumber;
  final String? email;
  final String? role;
  final String? dob;
  final Map<String, dynamic>? consent;
  final String? language;
  final List<String> courseIds;
  final String? token;

  UserModel({
    this.id,
    required this.phone,
    this.name,
    this.classNumber,
    this.email,
    this.role,
    this.dob,
    this.consent,
    this.language,
    this.courseIds = const [],
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'])?.toString(),
      phone: json['phone']?.toString() ?? json['mobile']?.toString() ?? '',
      name: json['name']?.toString(),
      classNumber: json['class']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      dob: json['dob']?.toString(),
      consent: json['consent'] is Map
          ? Map<String, dynamic>.from(json['consent'] as Map)
          : null,
      language: json['language']?.toString(),
      courseIds: json['courseIds'] is List
          ? (json['courseIds'] as List).map((id) => id.toString()).toList()
          : const [],
      token: json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'class': classNumber,
      'email': email,
      'role': role,
      'dob': dob,
      'consent': consent,
      'language': language,
      'courseIds': courseIds,
      'token': token,
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? classNumber,
    String? email,
    String? role,
    String? dob,
    Map<String, dynamic>? consent,
    String? language,
    List<String>? courseIds,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      classNumber: classNumber ?? this.classNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      dob: dob ?? this.dob,
      consent: consent ?? this.consent,
      language: language ?? this.language,
      courseIds: courseIds ?? this.courseIds,
      token: token ?? this.token,
    );
  }
}
