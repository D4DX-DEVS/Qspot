import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../models/video_model.dart';

class StorageService {
  static const String _progressKey = 'video_progress';
  static const String _videosKey = 'cached_videos';
  static const String _speakersKey = 'cached_speakers';
  static const String _lastUpdateKey = 'last_update';
  static const String _videoRemindersKey = 'video_reminders';

  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Ensure SharedPreferences is initialized
  static Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // Save video progress
  static Future<void> saveVideoProgress(String videoId, int progress) async {
    try {
      final prefs = await _preferences;
      final progressMap = await getVideoProgressMap();
      progressMap[videoId] = progress;

      final progressJson = json.encode(progressMap);
      await prefs.setString(_progressKey, progressJson);
    } catch (e) {
      debugPrint('Error saving video progress: $e');
    }
  }

  // Get video progress
  static Future<int> getVideoProgress(String videoId) async {
    try {
      final progressMap = await getVideoProgressMap();
      return progressMap[videoId] ?? 0;
    } catch (e) {
      debugPrint('Error getting video progress: $e');
      return 0;
    }
  }

  // Get all video progress as a map
  static Future<Map<String, int>> getVideoProgressMap() async {
    try {
      final prefs = await _preferences;
      final progressString = prefs.getString(_progressKey);

      if (progressString != null) {
        final Map<String, dynamic> decoded = json.decode(progressString);
        return decoded.map((key, value) => MapEntry(key, value as int));
      }

      return <String, int>{};
    } catch (e) {
      debugPrint('Error getting video progress map: $e');
      return <String, int>{};
    }
  }

  // Clear video progress
  static Future<void> clearVideoProgress(String videoId) async {
    try {
      final prefs = await _preferences;
      final progressMap = await getVideoProgressMap();
      progressMap.remove(videoId);

      final progressJson = json.encode(progressMap);
      await prefs.setString(_progressKey, progressJson);
    } catch (e) {
      debugPrint('Error clearing video progress: $e');
    }
  }

  // Clear all video progress
  static Future<void> clearAllVideoProgress() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_progressKey);
    } catch (e) {
      debugPrint('Error clearing all video progress: $e');
    }
  }

  // Cache videos locally
  static Future<void> cacheVideos(List<VideoModel> videos) async {
    try {
      final prefs = await _preferences;
      final videosJson = videos.map((video) => video.toJson()).toList();
      final videosString = json.encode(videosJson);

      await prefs.setString(_videosKey, videosString);
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error caching videos: $e');
    }
  }

  // Get cached videos
  static Future<List<VideoModel>> getCachedVideos() async {
    try {
      final prefs = await _preferences;
      final videosString = prefs.getString(_videosKey);

      if (videosString != null) {
        final List<dynamic> videosJson = json.decode(videosString);
        final videos = videosJson
            .map((videoJson) => VideoModel.fromJson(videoJson))
            .toList();

        // Update progress for cached videos
        final progressMap = await getVideoProgressMap();
        for (var video in videos) {
          video.progress = progressMap[video.id.toString()] ?? 0;
        }

        return videos;
      }

      return [];
    } catch (e) {
      debugPrint('Error getting cached videos: $e');
      return [];
    }
  }

  // Cache speakers locally
  static Future<void> cacheSpeakers(List<dynamic> speakers) async {
    try {
      final prefs = await _preferences;
      final speakersString = json.encode(speakers);

      await prefs.setString(_speakersKey, speakersString);
    } catch (e) {
      debugPrint('Error caching speakers: $e');
    }
  }

  // Get cached speakers
  static Future<List<dynamic>> getCachedSpeakers() async {
    try {
      final prefs = await _preferences;
      final speakersString = prefs.getString(_speakersKey);

      if (speakersString != null) {
        return json.decode(speakersString);
      }

      return [];
    } catch (e) {
      debugPrint('Error getting cached speakers: $e');
      return [];
    }
  }

  // Check if cache is fresh (within the last hour)
  static Future<bool> isCacheFresh({
    Duration maxAge = const Duration(hours: 1),
  }) async {
    try {
      final prefs = await _preferences;
      final lastUpdateString = prefs.getString(_lastUpdateKey);

      if (lastUpdateString != null) {
        final lastUpdate = DateTime.parse(lastUpdateString);
        final now = DateTime.now();
        return now.difference(lastUpdate) < maxAge;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking cache freshness: $e');
      return false;
    }
  }

  // Remove a key from storage
  static Future<bool> remove(String key) async {
    try {
      final prefs = await _preferences;
      return await prefs.remove(key);
    } catch (e) {
      debugPrint('Error removing key $key: $e');
      return false;
    }
  }

  // Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_videosKey);
      await prefs.remove(_speakersKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Get app preferences
  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    try {
      final prefs = await _preferences;
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Error getting bool preference: $e');
      return defaultValue;
    }
  }

  // Set app preferences
  static Future<void> setBool(String key, bool value) async {
    try {
      final prefs = await _preferences;
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error setting bool preference: $e');
    }
  }

  // Get string preference
  static Future<String> getString(
    String key, {
    String defaultValue = '',
  }) async {
    try {
      final prefs = await _preferences;
      return prefs.getString(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Error getting string preference: $e');
      return defaultValue;
    }
  }

  // Set string preference
  static Future<void> setString(String key, String value) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('Error setting string preference: $e');
    }
  }

  // Video Reminder Methods

  // Add video reminder
  static Future<void> addVideoReminder(
    String videoId,
    String videoTitle,
    DateTime releaseDate,
  ) async {
    try {
      final prefs = await _preferences;
      final reminders = await getVideoReminders();

      // Check if reminder already exists
      final existingIndex = reminders.indexWhere(
        (r) => r['videoId'] == videoId,
      );

      final reminderData = {
        'videoId': videoId,
        'videoTitle': videoTitle,
        'releaseDate': releaseDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      if (existingIndex >= 0) {
        // Update existing reminder
        reminders[existingIndex] = reminderData;
      } else {
        // Add new reminder
        reminders.add(reminderData);
      }

      final remindersJson = json.encode(reminders);
      await prefs.setString(_videoRemindersKey, remindersJson);
      debugPrint('📅 Video reminder added: $videoTitle (ID: $videoId)');
    } catch (e) {
      debugPrint('Error adding video reminder: $e');
    }
  }

  // Remove video reminder
  static Future<void> removeVideoReminder(String videoId) async {
    try {
      final prefs = await _preferences;
      final reminders = await getVideoReminders();

      reminders.removeWhere((r) => r['videoId'] == videoId);

      final remindersJson = json.encode(reminders);
      await prefs.setString(_videoRemindersKey, remindersJson);
      debugPrint('🗑️ Video reminder removed for ID: $videoId');
    } catch (e) {
      debugPrint('Error removing video reminder: $e');
    }
  }

  // Check if video reminder exists
  static Future<bool> hasVideoReminder(String videoId) async {
    try {
      final reminders = await getVideoReminders();
      return reminders.any((r) => r['videoId'] == videoId);
    } catch (e) {
      debugPrint('Error checking video reminder: $e');
      return false;
    }
  }

  // Get all video reminders
  static Future<List<Map<String, dynamic>>> getVideoReminders() async {
    try {
      final prefs = await _preferences;
      final remindersString = prefs.getString(_videoRemindersKey);

      if (remindersString != null) {
        final List<dynamic> decoded = json.decode(remindersString);
        return decoded.map((item) => item as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting video reminders: $e');
      return [];
    }
  }

  // Clear expired video reminders
  static Future<void> clearExpiredVideoReminders() async {
    try {
      final prefs = await _preferences;
      final reminders = await getVideoReminders();
      final now = DateTime.now();

      // Remove reminders for videos that have already been released
      final activeReminders = reminders.where((r) {
        final releaseDate = DateTime.parse(r['releaseDate'] as String);
        return releaseDate.isAfter(now);
      }).toList();

      final remindersJson = json.encode(activeReminders);
      await prefs.setString(_videoRemindersKey, remindersJson);

      final removedCount = reminders.length - activeReminders.length;
      if (removedCount > 0) {
        debugPrint('🗑️ Cleared $removedCount expired video reminders');
      }
    } catch (e) {
      debugPrint('Error clearing expired video reminders: $e');
    }
  }

  // Clear all video reminders
  static Future<void> clearAllVideoReminders() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_videoRemindersKey);
      debugPrint('🗑️ All video reminders cleared');
    } catch (e) {
      debugPrint('Error clearing all video reminders: $e');
    }
  }
}
