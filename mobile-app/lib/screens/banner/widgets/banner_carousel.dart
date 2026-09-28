import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/banner_model.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';

class BannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;
  final double height;

  const BannerCarousel({super.key, required this.banners, this.height = 180});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🎠 [BANNER CAROUSEL] Building with ${widget.banners.length} banners',
    );
    if (widget.banners.isEmpty) {
      debugPrint(
        '🎠 [BANNER CAROUSEL] Empty banners list, returning SizedBox.shrink()',
      );
      return const SizedBox.shrink();
    }

    for (var i = 0; i < widget.banners.length; i++) {
      debugPrint(
        '🎠 [BANNER CAROUSEL] Banner $i: ID=${widget.banners[i].id}, Image URL=${widget.banners[i].imageUrl}',
      );
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: widget.height,
            autoPlay: widget.banners.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: widget.banners.map((banner) {
            return Builder(
              builder: (BuildContext context) {
                return _buildBannerItem(banner);
              },
            );
          }).toList(),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: AppTheme.paddingSmall),
          _buildIndicators(),
        ],
      ],
    );
  }

  Widget _buildBannerItem(BannerModel banner) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: CachedNetworkImage(
          imageUrl: banner.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppTheme.surface,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.gradientEnd),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppTheme.surface,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 48,
                  color: AppTheme.secondaryGray,
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                Text(
                  'Image not available',
                  style: AppFonts.regular(
                    color: AppTheme.secondaryGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.banners.asMap().entries.map((entry) {
        return Container(
          width: _currentIndex == entry.key ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentIndex == entry.key
                ? AppTheme.gradientEnd
                : AppTheme.secondaryGray.withValues(alpha: 0.4),
          ),
        );
      }).toList(),
    );
  }
}
