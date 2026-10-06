import '../../../utils/json_parsing.dart';

/// A handout attached to an episode.
class VideoDownload {
  final String title;
  final String url;
  final String key;

  const VideoDownload({required this.title, required this.url, this.key = ''});

  factory VideoDownload.fromJson(Map<String, dynamic> json) {
    return VideoDownload(
      title: (json['title'] ?? '').toString().trim(),
      url: (json['url'] ?? '').toString().trim(),
      key: (json['key'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'url': url, 'key': key};
}

class VideoModel {
  final String id;
  final String caption;
  final String? thumbnail;
  final String video;
  final String? subjectId; // subject ID
  final String? subjectName; // subject name
  final String? speakerId; // faculty who presents this episode
  final String? speakerName;
  final String? speakerDesignation;
  final String? speakerImage;
  final String? title;
  final DateTime? date; // release date
  final String learnText;
  final List<String> learnPoints;
  final List<VideoDownload> downloads;
  final int order;
  final int durationSeconds;
  final int questionCount;

  /// Set directly from the server's `isUpcoming` flag. The server withholds
  /// [video] (empty string) for upcoming episodes.
  final bool isUpcoming;

  int progress; // seconds watched (legacy local-only hint; server progress
  // now drives the UI — see VideoProgressStatus)

  VideoModel({
    required this.id,
    required this.caption,
    this.thumbnail,
    required this.video,
    this.subjectId,
    this.subjectName,
    this.speakerId,
    this.speakerName,
    this.speakerDesignation,
    this.speakerImage,
    this.title,
    this.date,
    this.learnText = '',
    this.learnPoints = const [],
    this.downloads = const [],
    this.order = 0,
    this.durationSeconds = 0,
    this.questionCount = 0,
    this.isUpcoming = false,
    this.progress = 0,
  });

  // Factory constructor for JSON deserialization (server shape, or the
  // app's own cached shape from [toJson] — both round-trip cleanly).
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;

    if (json['releaseDate'] != null) {
      try {
        final dateStr = json['releaseDate'].toString();
        final formattedStr = dateStr.replaceAll('.', ':');
        parsedDate = DateTime.parse(formattedStr);
      } catch (_) {}
    } else if (json['date'] != null) {
      try {
        parsedDate = DateTime.parse(json['date'].toString());
      } catch (_) {}
    }

    // Handle subject (nested object from the API, or flat id/name from cache).
    String? subId;
    String? subName;
    if (json['subject'] is Map) {
      final subject = json['subject'] as Map<String, dynamic>;
      subId = subject['_id']?.toString();
      subName = subject['name']?.toString();
    } else if (json['sub'] != null) {
      subId = json['sub']?.toString();
    }
    subId ??= json['subjectId']?.toString();
    subName ??= json['subjectName']?.toString();

    // The API populates `speaker` for episodes that have a faculty assigned.
    String? speakerId;
    String? speakerName;
    String? speakerDesignation;
    String? speakerImage;
    if (json['speaker'] is Map) {
      final speaker = json['speaker'] as Map<String, dynamic>;
      speakerId = speaker['_id']?.toString();
      speakerName = speaker['name']?.toString();
      speakerDesignation = speaker['designation']?.toString();
      speakerImage = speaker['image']?.toString();
    } else if (json['speaker'] != null) {
      speakerId = json['speaker'].toString();
    }
    // Reading back from the local cache.
    speakerId ??= json['speakerId']?.toString();
    speakerName ??= json['speakerName']?.toString();
    speakerDesignation ??= json['speakerDesignation']?.toString();
    speakerImage ??= json['speakerImage']?.toString();

    final videoUrlValue = json['video']?.toString() ?? '';

    // The server tells us directly; fall back to the release-date heuristic
    // only for entries that predate that field (e.g. an old local cache).
    final bool upcoming = json.containsKey('isUpcoming')
        ? json['isUpcoming'] == true
        : (parsedDate != null && DateTime.now().isBefore(parsedDate));

    return VideoModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '0',
      caption: (json['description'] ?? json['caption'])?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      video: videoUrlValue,
      subjectId: subId,
      subjectName: subName,
      speakerId: speakerId,
      speakerName: speakerName,
      speakerDesignation: speakerDesignation,
      speakerImage: speakerImage,
      title: json['title']?.toString(),
      date: parsedDate,
      learnText: (json['learnText'] ?? '').toString().trim(),
      learnPoints: json['learnPoints'] is List
          ? (json['learnPoints'] as List)
                .map((point) => point.toString().trim())
                .where((point) => point.isNotEmpty)
                .toList()
          : const [],
      downloads: json['downloads'] is List
          ? (json['downloads'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      VideoDownload.fromJson(Map<String, dynamic>.from(item)),
                )
                .where((item) => item.title.isNotEmpty && item.url.isNotEmpty)
                .toList()
          : const [],
      order: jsonInt(json['order']) ?? 0,
      durationSeconds: jsonInt(json['durationSeconds']) ?? 0,
      questionCount: jsonInt(json['questionCount']) ?? 0,
      isUpcoming: upcoming,
      progress: jsonInt(json['progress']) ?? 0,
    );
  }

  // Convert to JSON for local (1-hour) caching. Round-trips every field so
  // the cache never silently loses learn notes, downloads, etc.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'thumbnail': thumbnail,
      'video': video,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'speakerId': speakerId,
      'speakerName': speakerName,
      'speakerDesignation': speakerDesignation,
      'speakerImage': speakerImage,
      'title': title,
      'date': date?.toIso8601String(),
      'learnText': learnText,
      'learnPoints': learnPoints,
      'downloads': downloads.map((d) => d.toJson()).toList(),
      'order': order,
      'durationSeconds': durationSeconds,
      'questionCount': questionCount,
      'isUpcoming': isUpcoming,
      'progress': progress,
    };
  }

  // Helper method to get video ID from URL
  String get videoId => id;

  // Formatted duration from the server's durationSeconds, e.g. "12:34" or
  // "1:02:34". Falls back to "--:--" when unknown (e.g. still loading).
  String get formattedDuration {
    if (durationSeconds <= 0) return '--:--';
    final duration = Duration(seconds: durationSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final mm = minutes.toString().padLeft(hours > 0 ? 2 : 1, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }

  // Helper method to check if video has (legacy local) progress
  bool get hasProgress => progress > 0;

  // Helper method to get display title (using caption)
  String get displayTitle =>
      title?.isNotEmpty == true ? title! : 'Untitled Video';

  /// Some episodes were published twice — once plainly and once with a
  /// trailing "| Class NN" — so this collapses both copies onto one key.
  String get episodeKey {
    // Built from the raw title: with no title there is nothing to group on, so
    // the video stands on its own id rather than merging with other untitled
    // entries.
    final cleaned = (title ?? '')
        .split('|')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where(
          (part) =>
              !RegExp(r'^class\s*\d+$', caseSensitive: false).hasMatch(part),
        )
        .join(' | ')
        .replaceAll(RegExp(r'[\u200c\u200d]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase()
        .trim();

    return cleaned.isEmpty ? id : cleaned;
  }

  /// First copy wins, so the caller's ordering decides which is kept.
  static List<VideoModel> distinctEpisodes(Iterable<VideoModel> videos) {
    final seen = <String>{};
    return videos.where((video) => seen.add(video.episodeKey)).toList();
  }

  // Helper method to get thumbnail URL or an empty string when there is none
  // (the UI falls back to a local icon placeholder, never a stock photo URL).
  String get thumbnailUrl {
    if (thumbnail != null && thumbnail!.isNotEmpty) {
      return thumbnail!;
    }
    if (video.isNotEmpty &&
        (video.contains('youtube.com') || video.contains('youtu.be'))) {
      final ytThumbnail = getYouTubeThumbnail(video);
      if (ytThumbnail.isNotEmpty) {
        return ytThumbnail;
      }
    }
    return '';
  }

  // Helper method to get video URL
  String get videoUrl => video.isNotEmpty ? video : '';

  // Extract YouTube thumbnail from URL
  String getYouTubeThumbnail(String youtubeUrl) {
    try {
      if (youtubeUrl.isEmpty) return '';

      String? videoId;

      if (youtubeUrl.contains('youtube.com/shorts/')) {
        final match = RegExp(
          r'shorts/([a-zA-Z0-9_-]{11})',
        ).firstMatch(youtubeUrl);
        videoId = match?.group(1);
      } else if (youtubeUrl.contains('youtu.be/')) {
        final match = RegExp(
          r'youtu\.be/([a-zA-Z0-9_-]{11})',
        ).firstMatch(youtubeUrl);
        videoId = match?.group(1);
      } else if (youtubeUrl.contains('youtube.com/watch')) {
        final match = RegExp(
          r'[?&]v=([a-zA-Z0-9_-]{11})',
        ).firstMatch(youtubeUrl);
        videoId = match?.group(1);
      } else if (youtubeUrl.contains('youtube.com/live/')) {
        final match = RegExp(
          r'live/([a-zA-Z0-9_-]{11})',
        ).firstMatch(youtubeUrl);
        videoId = match?.group(1);
      }

      if (videoId != null && videoId.isNotEmpty) {
        return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
      }
    } catch (_) {}

    return '';
  }

  // Helper method to check if it's a YouTube video
  bool get isYouTubeVideo {
    return video.isNotEmpty &&
        (video.contains('youtube.com') || video.contains('youtu.be'));
  }

  // Helper method to check if it's a live video
  bool get isLiveVideo {
    return video.isNotEmpty && video.contains('youtube.com/live/');
  }

  /// YouTube Shorts are vertical. Everything uploaded to the QSPOT channel is a
  /// Short, so the player uses a 9:16 box for these and 16:9 otherwise.
  bool get isPortrait {
    if (video.isEmpty) return false;
    return video.contains('/shorts/') || video.contains('youtube.com/shorts');
  }

  double get playerAspectRatio => isPortrait ? 9 / 16 : 16 / 9;

  // Helper method to get formatted date
  String get formattedDate {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date!);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // Copy with method for updating progress
  VideoModel copyWith({
    String? id,
    String? caption,
    String? thumbnail,
    String? video,
    String? subjectId,
    String? subjectName,
    String? speakerId,
    String? speakerName,
    String? title,
    DateTime? date,
    int? progress,
  }) {
    return VideoModel(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      thumbnail: thumbnail ?? this.thumbnail,
      video: video ?? this.video,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      speakerId: speakerId ?? this.speakerId,
      speakerName: speakerName ?? this.speakerName,
      speakerDesignation: speakerDesignation,
      speakerImage: speakerImage,
      title: title ?? this.title,
      date: date ?? this.date,
      learnText: learnText,
      learnPoints: learnPoints,
      downloads: downloads,
      order: order,
      durationSeconds: durationSeconds,
      questionCount: questionCount,
      isUpcoming: isUpcoming,
      progress: progress ?? this.progress,
    );
  }

  // Helper method to get date published
  DateTime get datePublished => date ?? DateTime.now();

  // Helper method for description (using caption)
  String get description =>
      caption.isNotEmpty ? caption : 'No description available';

  // Helper method for speaker IDs (placeholder since not in current API)
  List<String> get speakerIds => [];

  // Check if video is available (i.e. not upcoming)
  bool get isAvailable => !isUpcoming;

  // Get formatted date for upcoming videos
  String get upcomingDateFormatted {
    if (date == null || !isUpcoming) return '';

    final now = DateTime.now();
    final difference = date!.difference(now);

    if (difference.inMinutes < 60) {
      return 'Available in ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'Available in ${difference.inHours} hours';
    } else if (difference.inDays == 1) {
      return 'Available tomorrow';
    } else if (difference.inDays < 7) {
      return 'Available in ${difference.inDays} days';
    } else {
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
      return 'Available on ${months[date!.month - 1]} ${date!.day}, ${date!.year}';
    }
  }

  // Get short date/time format for upcoming videos
  String get upcomingDateTime {
    if (date == null) return '';

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
    final hour = date!.hour > 12
        ? date!.hour - 12
        : (date!.hour == 0 ? 12 : date!.hour);
    final minute = date!.minute.toString().padLeft(2, '0');
    final period = date!.hour >= 12 ? 'PM' : 'AM';

    return '${months[date!.month - 1]} ${date!.day}, ${date!.year} at $hour:$minute $period';
  }
}
