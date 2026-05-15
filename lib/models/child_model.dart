class ChildModel {
  final String id;
  final String orphanageId;
  final String orphanageName;
  final String orphanagePhone;
  final String orphanageEmail;
  final String name;
  final int age;
  final String gender;
  final String location;
  final String healthStatus;
  final String description;
  final String photoUrl;
  final bool availableForAdoption;
  final bool isAdopted;
  final DateTime createdAt;
  final List<String> interestedFamilies;

  ChildModel({
    required this.id,
    required this.orphanageId,
    required this.orphanageName,
    required this.orphanagePhone,
    required this.orphanageEmail,
    required this.name,
    required this.age,
    required this.gender,
    required this.location,
    required this.healthStatus,
    required this.description,
    required this.photoUrl,
    this.availableForAdoption = true,
    this.isAdopted = false,
    required this.createdAt,
    this.interestedFamilies = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orphanageId': orphanageId,
      'orphanageName': orphanageName,
      'orphanagePhone': orphanagePhone,
      'orphanageEmail': orphanageEmail,
      'name': name,
      'age': age,
      'gender': gender,
      'location': location,
      'healthStatus': healthStatus,
      'description': description,
      'photoUrl': photoUrl,
      'availableForAdoption': availableForAdoption,
      'isAdopted': isAdopted,
      'createdAt': createdAt.toIso8601String(),
      'interestedFamilies': interestedFamilies,
    };
  }

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id: map['id'] ?? '',
      orphanageId: map['orphanageId'] ?? '',
      orphanageName: map['orphanageName'] ?? '',
      orphanagePhone: map['orphanagePhone'] ?? '',
      orphanageEmail: map['orphanageEmail'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      location: map['location'] ?? '',
      healthStatus: map['healthStatus'] ?? '',
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      availableForAdoption: map['availableForAdoption'] ?? true,
      isAdopted: map['isAdopted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      interestedFamilies: List<String>.from(map['interestedFamilies'] ?? []),
    );
  }

  ChildModel copyWith({
    String? id,
    String? orphanageId,
    String? orphanageName,
    String? orphanagePhone,
    String? orphanageEmail,
    String? name,
    int? age,
    String? gender,
    String? location,
    String? healthStatus,
    String? description,
    String? photoUrl,
    bool? availableForAdoption,
    bool? isAdopted,
    DateTime? createdAt,
    List<String>? interestedFamilies,
  }) {
    return ChildModel(
      id: id ?? this.id,
      orphanageId: orphanageId ?? this.orphanageId,
      orphanageName: orphanageName ?? this.orphanageName,
      orphanagePhone: orphanagePhone ?? this.orphanagePhone,
      orphanageEmail: orphanageEmail ?? this.orphanageEmail,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      healthStatus: healthStatus ?? this.healthStatus,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      availableForAdoption: availableForAdoption ?? this.availableForAdoption,
      isAdopted: isAdopted ?? this.isAdopted,
      createdAt: createdAt ?? this.createdAt,
      interestedFamilies: interestedFamilies ?? this.interestedFamilies,
    );
  }
}