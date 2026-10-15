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
import '../../../widgets/common/gradient_card.dart';

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
    if (_isWeeklyQuizBanner(banner)) return _buildQuizBanner(p);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GradientCard.radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GradientCard.radius),
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

  bool _isWeeklyQuizBanner(BannerModel banner) {
    final type = banner.type?.trim().toLowerCase() ?? '';
    final title = banner.title?.trim().toLowerCase() ?? '';
    if (type == 'weekly_quiz' || title.contains('weekly quiz')) return true;

    // Keep compatibility with the seeded placeholder banners until the API
    // starts returning explicit banner metadata.
    final uri = Uri.tryParse(banner.imageUrl);
    final text = uri?.queryParameters['text']?.toLowerCase() ?? '';
    return text.contains('weekly quiz');
  }

  Widget _buildQuizBanner(HomePalette palette) {
    return Semantics(
      label:
          'Weekly Quiz is Live. Test your knowledge and keep your learning streak alive.',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(GradientCard.radius),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: 26,
              top: 24,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.amber.color.withValues(alpha: 0.14),
                  border: Border.all(
                    color: palette.amber.color.withValues(alpha: 0.42),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  LucideIcons.trophy,
                  color: palette.amber.color,
                  size: 38,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 128, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'WEEKLY QUIZ',
                    style: AppFonts.bold(
                      color: palette.amber.color,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Weekly Quiz is Live',
                    style: AppFonts.bold(color: AppColors.white, fontSize: 21),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Test your knowledge and keep your learning streak alive.',
                    style: AppFonts.regular(
                      color: AppColors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
