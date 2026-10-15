import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/count_up_text.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../../widgets/common/surface_card.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../../video/model/video_model.dart';
import '../../video/provider/video_provider.dart';
import '../../video/screens/video_reels_screen.dart';
import '../model/speaker_model.dart';
import '../provider/faculties_screen_provider.dart';
import '../provider/speaker_provider.dart';

/// One full profile per faculty member, stacked so scrolling moves from one
/// person to the next. Search narrows the list instead.
class FacultiesScreen extends StatefulWidget {
  const FacultiesScreen({super.key});

  @override
  State<FacultiesScreen> createState() => _FacultiesScreenState();
}

class _FacultiesScreenState extends State<FacultiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FacultiesScreenProvider _faculties = FacultiesScreenProvider();

  @override
  void dispose() {
    _searchController.dispose();
    _faculties.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(
      child: ChangeNotifierProvider.value(
        value: _faculties,
        child: Consumer<FacultiesScreenProvider>(
          builder: (context, search, _) => _buildPage(context, search),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, FacultiesScreenProvider search) {
    final p = HomePalette.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Faculties',
        titleWidget: search.isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppFonts.regular(color: p.text),
                decoration: InputDecoration(
                  hintText: 'Search Faculties…',
                  hintStyle: AppFonts.regular(color: p.textMuted),
                  border: InputBorder.none,
                ),
                onChanged: search.setQuery,
              )
            : null,
        actions: [
          IconButton(
            tooltip: search.isSearching ? 'Close Search' : 'Search Faculties',
            icon: Icon(
              search.isSearching ? LucideIcons.x : LucideIcons.search,
              color: p.text,
            ),
            onPressed: () {
              if (search.isSearching) _searchController.clear();
              search.toggleSearching();
            },
          ),
        ],
      ),
      body: Consumer2<SpeakerProvider, VideoProvider>(
        builder: (context, speakerProvider, videoProvider, child) {
          if (speakerProvider.isLoading && speakerProvider.speakers.isEmpty) {
            return const LoadingSkeleton();
          }

          if (speakerProvider.hasError && speakerProvider.speakers.isEmpty) {
            return StateMessageView(
              icon: LucideIcons.circleAlert,
              title: 'Could Not Load Faculties',
              message: speakerProvider.errorMessage,
              onRetry: () => speakerProvider.refresh(),
            );
          }

          final all = speakerProvider.speakers;
          final faculties = search.filter(all);

          if (all.isEmpty) {
            return const StateMessageView(
              icon: LucideIcons.users,
              title: 'No Faculties Yet',
              message: 'Faculty profiles will appear here once they are added.',
            );
          }

          if (faculties.isEmpty) {
            return StateMessageView(
              icon: LucideIcons.searchX,
              title: 'No Match for "${search.query}"',
              message: 'Try a different name.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => speakerProvider.refresh(),
            backgroundColor: p.card,
            color: p.brand,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: faculties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final speaker = faculties[index];
                return StaggeredEntrance(
                  index: index,
                  child: _FacultyProfile(
                    speaker: speaker,
                    episodes: videoProvider.videosForSpeaker(speaker.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// A single faculty member: portrait, role, about, and their episodes.
class _FacultyProfile extends StatelessWidget {
  const _FacultyProfile({required this.speaker, required this.episodes});

  final SpeakerModel speaker;
  final List<VideoModel> episodes;

  static const double _photoHeight = 220;

  /// Tallest the portrait grows to when big system text needs more room for
  /// the name drawn on it.
  static const double _maxPhotoHeight = 320;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      radius: 22,
      color: p.card,
      borderColor: p.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _portrait(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (speaker.designation.isNotEmpty)
                  Text(
                    speaker.designation,
                    style: AppFonts.medium(
                      color: p.text,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                const SizedBox(height: 16),
                _episodeSummary(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _portrait(BuildContext context) {
    final p = HomePalette.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: (_photoHeight * textScale).clamp(_photoHeight, _maxPhotoHeight),
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (speaker.avatarUrl != null)
            CachedNetworkImage(
              imageUrl: speaker.avatarUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: p.brandSoft),
              errorWidget: (_, __, ___) => _initials(p),
            )
          else
            _initials(p),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [AppColors.transparent, AppColors.scrimStrong],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker.name,
                  style: AppFonts.bold(
                    color: AppColors.white,
                    fontSize: 22,
                    height: 1.2,
                  ),
                ),
                if (episodes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  CountUpText(
                    '${episodes.length} Episode${episodes.length == 1 ? '' : 's'}',
                    style: AppFonts.semiBold(
                      color: AppColors.white70,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initials(HomePalette p) {
    final initials = speaker.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        // runes so a multi-byte first character survives intact
        .map((part) => String.fromCharCode(part.runes.first).toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(gradient: p.heroGradient),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: AppFonts.bold(color: AppColors.white, fontSize: 44),
      ),
    );
  }

  Widget _episodeSummary(BuildContext context) {
    final p = HomePalette.of(context);
    if (episodes.isEmpty) {
      return Text(
        'No episodes published yet.',
        style: AppFonts.regular(color: p.textMuted, fontSize: 13.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EPISODES',
          style: AppFonts.bold(
            color: p.textMuted,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ...episodes
            .take(3)
            .map(
              (episode) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PressableScale(
                  pressedScale: 0.98,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => VideoReelsScreen.open(
                      context,
                      episodes,
                      initialIndex: episodes.indexOf(episode),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SoftIconTile(
                            icon: LucideIcons.play,
                            tone: p.rose,
                            size: 32,
                            circle: true,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              episode.displayTitle,
                              style: AppFonts.regular(
                                color: p.text,
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: PressableScale(
            haptic: true,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: p.brand,
                foregroundColor: p.card,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: AppFonts.bold(fontSize: 14),
              ),
              onPressed: () => VideoReelsScreen.open(context, episodes),
              child: Text(
                'Watch All ${episodes.length} Episode'
                '${episodes.length == 1 ? '' : 's'}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
