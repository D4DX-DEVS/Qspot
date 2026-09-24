class BannerModel {
  final String id;
  final String image;

  BannerModel({required this.id, required this.image});

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '0',
      image: json['image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'image': image};
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
