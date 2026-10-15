import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/downloads/model/offline_file.dart';
import '../../screens/downloads/model/offline_lesson.dart';

/// Where saved lessons live: files in the app's own folder, and the list of
/// them in the phone's preferences.
class OfflineStore {
  OfflineStore({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationDocumentsDirectory;

  static const _key = 'offline_lessons';
  final Future<Directory> Function() _baseDir;

  Future<Directory> folder() async {
    final dir = Directory(p.join((await _baseDir()).path, 'offline_lessons'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<List<OfflineLesson>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => OfflineLesson.fromJson(Map<String, dynamic>.from(e)))
          // A file removed by the phone (storage cleanup) drops the lesson.
          .where((l) => l.files.every((f) => File(f.path).existsSync()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<OfflineLesson> lessons) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(lessons.map((l) => l.toJson()).toList()),
    );
  }

  Future<void> deleteFiles(Iterable<OfflineFile> files) async {
    for (final file in files) {
      final f = File(file.path);
      if (await f.exists()) await f.delete();
    }
  }

  /// Everything saved, gone (logout on a shared phone).
  Future<void> clear() async {
    final dir = await folder();
    if (await dir.exists()) await dir.delete(recursive: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
