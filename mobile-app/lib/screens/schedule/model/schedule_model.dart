import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleModel {
  final String id;
  final String classNumber;
  final String title;
  final DateTime date;
  final String faculty;
  final String? facultyName;

  ScheduleModel({
    required this.id,
    required this.classNumber,
    required this.title,
    required this.date,
    required this.faculty,
    this.facultyName,
  });

  // Factory constructor for JSON deserialization
  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    // Handle both new API (scheduleDate) and old API (date)
    final dateField = json['scheduleDate'] ?? json['date'];
    if (dateField != null) {
      try {
        parsedDate = DateTime.parse(dateField.toString());
      } catch (e) {
        debugPrint('Error parsing schedule date: $e');
      }
    }

    // Handle nested faculty object from new API
    String facultyId = '0';
    String? facultyName;
    if (json['faculty'] is Map) {
      final facultyObj = json['faculty'] as Map<String, dynamic>;
      facultyId = facultyObj['_id']?.toString() ?? '0';
      facultyName = facultyObj['name']?.toString();
    } else if (json['faculty'] != null) {
      facultyId = json['faculty'].toString();
    }

    return ScheduleModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '0',
      classNumber: json['class']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: parsedDate,
      faculty: facultyId,
      facultyName: facultyName,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class': classNumber,
      'title': title,
      'date': date.toIso8601String(),
      'faculty': faculty,
    };
  }

  // Get formatted date
  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Get formatted time
  String get formattedTime {
    return DateFormat('hh:mm a').format(date);
  }

  // Get formatted date and time
  String get formattedDateTime {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  // Get day of week
  String get dayOfWeek {
    return DateFormat('EEEE').format(date);
  }

  // Check if schedule is in the past
  bool get isPast {
    return date.isBefore(DateTime.now());
  }

  // Check if schedule is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if schedule is upcoming (future)
  bool get isUpcoming {
    return date.isAfter(DateTime.now());
  }

  // Get relative time (e.g., "Today", "Tomorrow", "In 3 days")
  String get relativeTime {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (isPast) {
      if (difference.inDays == 0) {
        return 'Earlier today';
      } else if (difference.inDays == -1) {
        return 'Yesterday';
      } else if (difference.inDays > -7) {
        return '${difference.inDays.abs()} days ago';
      } else {
        return formattedDate;
      }
    } else {
      if (isToday) {
        if (difference.inHours < 1) {
          return 'In ${difference.inMinutes} minutes';
        } else {
          return 'Today at $formattedTime';
        }
      } else if (difference.inDays == 1) {
        return 'Tomorrow at $formattedTime';
      } else if (difference.inDays < 7) {
        return 'In ${difference.inDays} days';
      } else {
        return formattedDate;
      }
    }
  }

  // Get status color based on schedule timing
  String get statusText {
    if (isPast) {
      return 'Completed';
    } else if (isToday) {
      return 'Today';
    } else {
      return 'Upcoming';
    }
  }
}
