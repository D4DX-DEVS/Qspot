class NotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime? createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    this.createdAt,
    this.isRead = false,
  });

  // Factory constructor for JSON deserialization
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    // Handle both new API (createdAt) and old API (date_created)
    final dateField = json['createdAt'] ?? json['date_created'];
    if (dateField != null) {
      try {
        parsedDate = DateTime.parse(dateField.toString());
      } catch (e) {
        // If parsing fails, use current time
        parsedDate = DateTime.now();
      }
    }

    return NotificationModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '0',
      title: json['title']?.toString() ?? '',
      description:
          json['description']?.toString() ??
          json['decription']?.toString() ??
          '', // Handle both spellings
      createdAt: parsedDate,
      isRead: false, // Default to unread
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_created': createdAt?.toIso8601String(),
      'is_read': isRead,
    };
  }

  // Helper method to get formatted date
  String get formattedDate {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  // Helper method to get formatted full date
  String get formattedFullDate {
    if (createdAt == null) return '';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[createdAt!.month - 1];
    final day = createdAt!.day;
    final year = createdAt!.year;
    final hour = createdAt!.hour;
    final minute = createdAt!.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$month $day, $year at $displayHour:$minute $amPm';
  }

  // Copy with method for updating read status
  NotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
