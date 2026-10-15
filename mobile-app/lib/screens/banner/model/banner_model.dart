class BannerModel {
  final String id;
  final String image;
  final String? title;
  final String? type;

  BannerModel({required this.id, required this.image, this.title, this.type});

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '0',
      image: json['image']?.toString() ?? '',
      title: json['title']?.toString(),
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
    };
  }

  // Return the image URL only if it's already a full URL from the API.
  // No image (or a non-absolute legacy path) means "no image" — an empty
  // string here (rather than a hardcoded third-party/CMS URL) lets
  // BannerCarousel's existing CachedNetworkImage errorWidget show a local
  // placeholder instead of hitting an external host.
  String get imageUrl {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }
    return '';
  }
}
