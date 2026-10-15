import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../services/downloads/file_downloader.dart';
import '../../../services/downloads/offline_store.dart';
import '../../video/model/video_model.dart';
import '../model/lesson_download_plan.dart';
import '../model/offline_file.dart';
import '../model/offline_lesson.dart';

/// Lessons saved on this phone for offline use, and the ones being saved.
class DownloadsProvider extends ChangeNotifier {
  DownloadsProvider({OfflineStore? store, FileDownloader? downloader})
    : _store = store ?? OfflineStore(),
      _downloader = downloader ?? FileDownloader() {
    active = this;
  }

  /// The app's instance, for code outside the widget tree's providers (the
  /// player and handout viewer look up saved copies through it).
  static DownloadsProvider? active;

  static const failedMessage =
      "Couldn't save this lesson. Check your connection and the space on "
      'your phone, then try again.';

  final OfflineStore _store;
  final FileDownloader _downloader;

  List<OfflineLesson> _lessons = [];
  bool _loaded = false;
  final Map<String, double?> _progress = {};
  final Set<String> _cancelled = {};
  final Map<String, String> _errors = {};

  List<OfflineLesson> get lessons => List.unmodifiable(_lessons);
  int get totalBytes => _lessons.fold(0, (sum, l) => sum + l.bytes);

  bool isSaved(String lessonId) => _lessons.any((l) => l.lessonId == lessonId);
  bool isSaving(String lessonId) => _progress.containsKey(lessonId);

  /// 0–1 while saving; null when the size isn't known yet.
  double? progressFor(String lessonId) => _progress[lessonId];
  String? errorFor(String lessonId) => _errors[lessonId];

  OfflineLesson? lessonFor(String lessonId) {
    for (final l in _lessons) {
      if (l.lessonId == lessonId) return l;
    }
    return null;
  }

  /// The saved copy of a file downloaded from [url], if it is on the phone.
  String? localPathFor(String url) {
    for (final lesson in _lessons) {
      for (final file in lesson.files) {
        if (file.url == url && File(file.path).existsSync()) return file.path;
      }
    }
    return null;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _lessons = await _store.load();
    _loaded = true;
    notifyListeners();
  }

  /// Saves the lesson's video (when it isn't on YouTube) and handouts.
  Future<void> save(VideoModel video) async {
    await ensureLoaded();
    final id = video.id;
    final plan = LessonDownloadPlan.filesFor(video);
    if (plan.isEmpty || isSaving(id)) return;
    _progress[id] = 0;
    _errors.remove(id);
    notifyListeners();

    final saved = <OfflineFile>[];
    try {
      final folder = await _store.folder();
      for (final (i, item) in plan.indexed) {
        final target = File(
          p.join(folder.path, '$id-$i${_extension(item.url)}'),
        );
        final bytes = await _downloader.download(
          item.url,
          target,
          onProgress: (received, total) =>
              _setProgress(id, i, plan.length, received, total),
          isCancelled: () => _cancelled.contains(id),
        );
        saved.add(
          OfflineFile(
            url: item.url,
            path: target.path,
            name: item.name,
            kind: item.kind,
            bytes: bytes,
          ),
        );
      }
      final old = lessonFor(id);
      _lessons = [
        ..._lessons.where((l) => l.lessonId != id),
        OfflineLesson(
          lessonId: id,
          title: video.displayTitle,
          files: saved,
          savedAt: DateTime.now(),
        ),
      ];
      await _store.save(_lessons);
      if (old != null) {
        await _store.deleteFiles(
          old.files.where((f) => !saved.any((s) => s.path == f.path)),
        );
      }
    } on DownloadCancelled {
      await _store.deleteFiles(saved);
    } catch (_) {
      await _store.deleteFiles(saved);
      _errors[id] = failedMessage;
    } finally {
      _progress.remove(id);
      _cancelled.remove(id);
      notifyListeners();
    }
  }

  void cancel(String lessonId) => _cancelled.add(lessonId);

  Future<void> remove(String lessonId) async {
    final lesson = lessonFor(lessonId);
    if (lesson == null) return;
    _lessons = _lessons.where((l) => l.lessonId != lessonId).toList();
    notifyListeners();
    await _store.save(_lessons);
    await _store.deleteFiles(lesson.files);
  }

  Future<void> removeAll() async {
    _cancelled.addAll(_progress.keys);
    _lessons = [];
    notifyListeners();
    await _store.clear();
  }

  // Overall progress across the lesson's files, notified in 1% steps so the
  // screen isn't rebuilt for every chunk.
  void _setProgress(String id, int index, int count, int received, int? total) {
    final value = total == null || total <= 0
        ? null
        : ((index + received / total) / count).clamp(0.0, 1.0);
    final previous = _progress[id];
    final changed = value == null || previous == null
        ? value != previous
        : (value - previous).abs() >= 0.01 || value == 1.0;
    if (!changed) return;
    _progress[id] = value;
    notifyListeners();
  }

  static String _extension(String url) {
    final ext = p.extension(Uri.tryParse(url)?.path ?? '');
    return ext.length <= 6 ? ext : '';
  }
}
