/// One file saved on the phone for offline use: a lesson video or a handout.
class OfflineFile {
  const OfflineFile({
    required this.url,
    required this.path,
    required this.name,
    required this.kind,
    required this.bytes,
  });

  /// Where it was downloaded from; used to find the saved copy.
  final String url;
  final String path;
  final String name;

  /// `video` or `handout`.
  final String kind;
  final int bytes;

  bool get isVideo => kind == 'video';

  Map<String, dynamic> toJson() => {
    'url': url,
    'path': path,
    'name': name,
    'kind': kind,
    'bytes': bytes,
  };

  factory OfflineFile.fromJson(Map<String, dynamic> json) => OfflineFile(
    url: (json['url'] ?? '').toString(),
    path: (json['path'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    kind: (json['kind'] ?? 'handout').toString(),
    bytes: json['bytes'] is int ? json['bytes'] as int : 0,
  );
}
