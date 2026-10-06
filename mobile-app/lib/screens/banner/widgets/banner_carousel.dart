import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/banner_model.dart';
import '../provider/banner_carousel_provider.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/motion.dart';
import '../../../widgets/animation/staggered_entrance.dart';

class BannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;
  final double height;

  const BannerCarousel({super.key, required this.banners, this.height = 180});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final BannerCarouselProvider _carousel = BannerCarouselProvider();

  @override
  void dispose() {
    _carousel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _carousel,
      child: Consumer<BannerCarouselProvider>(
        builder: (_, carousel, __) => _buildPage(carousel),
      ),
    );
  }

  Widget _buildPage(BannerCarouselProvider carousel) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return StaggeredEntrance(
      child: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: widget.height,
              autoPlay: widget.banners.length > 1,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: false,
              viewportFraction: 1,
              onPageChanged: (index, reason) => carousel.setIndex(index),
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
            _buildIndicators(carousel),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerItem(BannerModel banner) {
    final p = HomePalette.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
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
            color: p.card,
            child: Center(child: CircularProgressIndicator(color: p.brand)),
          ),
          errorWidget: (context, url, error) => Container(
            color: p.card,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.imageOff, size: 48, color: p.textMuted),
                const SizedBox(height: AppTheme.paddingSmall),
                Text(
                  'Image Not Available',
                  style: AppFonts.regular(color: p.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicators(BannerCarouselProvider carousel) {
    final p = HomePalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.banners.asMap().entries.map((entry) {
        return AnimatedContainer(
          duration: Motion.reduced(context) ? Duration.zero : Motion.medium,
          curve: Motion.smooth,
          width: carousel.currentIndex == entry.key ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: carousel.currentIndex == entry.key
                ? p.brand
                : p.textMuted.withValues(alpha: 0.4),
          ),
        );
      }).toList(),
    );
  }
}
