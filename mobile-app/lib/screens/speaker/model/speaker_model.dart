class SpeakerModel {
  final String id;
  final String name;
  final String designation;
  final String? photo;
  final String? order; // Order field for sorting speakers

  SpeakerModel({
    required this.id,
    required this.name,
    required this.designation,
    this.photo,
    this.order,
  });

  // Factory constructor for JSON deserialization
  factory SpeakerModel.fromJson(Map<String, dynamic> json) {
    return SpeakerModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '0',
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      photo: (json['image'] ?? json['photo'])?.toString(),
      order: json['order']?.toString(),
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'designation': designation,
      'photo': photo,
      'order': order,
    };
  }

  // Helper method to get full avatar URL. The API always returns a full
  // URL for the speaker image; when there is none, return null and let the
  // UI fall back to a local placeholder/icon instead of a third-party URL.
  String? get avatarUrl {
    if (photo != null && photo!.isNotEmpty) {
      if (photo!.startsWith('http://') || photo!.startsWith('https://')) {
        return photo!;
      }
    }
    return null;
  }

  // Helper method to get display title (using designation)
  String get title => designation.isNotEmpty ? designation : 'Speaker';

  // Helper method to get organization from designation
  String get organization {
    // Extract organization from designation if it contains a comma
    if (designation.contains(',')) {
      final parts = designation.split(',');
      if (parts.length > 1) {
        return parts.last.trim();
      }
    }
    return designation;
  }

  // Helper method to get role from designation
  String get role {
    // Extract role from designation if it contains a comma
    if (designation.contains(',')) {
      final parts = designation.split(',');
      if (parts.isNotEmpty) {
        return parts.first.trim();
      }
    }
    return designation;
  }

  // Helper method to get short bio (using designation as bio for now)
  String getShortBio([int maxLength = 100]) {
    final bio = designation;
    if (bio.length <= maxLength) return bio;
    return '${bio.substring(0, maxLength)}...';
  }

  // Helper method to get full bio (using designation)
  String get bio => designation;

  // Helper method to get speaker ID as string
  String get speakerId => id;

  // Helper method to get order as integer for sorting
  int get orderValue {
    if (order == null || order!.isEmpty) {
      return 999999; // Speakers without order go to end
    }
    try {
      return int.parse(order!);
    } catch (e) {
      return 999999; // Invalid order values go to end
    }
  }
}
