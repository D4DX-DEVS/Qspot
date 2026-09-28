import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../video/model/video_model.dart';
import '../../video/provider/video_provider.dart';
import '../../video/screens/video_reels_screen.dart';
import '../model/speaker_model.dart';
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
  bool _isSearching = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: CommonAppBar(
        title: 'Faculties',
        titleWidget: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppFonts.regular(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search faculties…',
                  hintStyle: AppFonts.regular(color: AppTheme.textMuted),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              )
            : null,
        actions: [
          IconButton(
            tooltip: _isSearching ? 'Close search' : 'Search faculties',
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _query = '';
                }
              });
            },
          ),
        ],
      ),
      body: Consumer2<SpeakerProvider, VideoProvider>(
        builder: (context, speakerProvider, videoProvider, child) {
          if (speakerProvider.isLoading && speakerProvider.speakers.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (speakerProvider.hasError && speakerProvider.speakers.isEmpty) {
            return _message(
              icon: Icons.error_outline,
              title: 'Could not load faculties',
              subtitle: speakerProvider.errorMessage,
              action: TextButton(
                onPressed: () => speakerProvider.refresh(),
                child: const Text('Try again'),
              ),
            );
          }

          final all = speakerProvider.speakers;
          final faculties = _query.isEmpty
              ? all
              : all.where((speaker) => _matches(speaker, _query)).toList();

          if (all.isEmpty) {
            return _message(
              icon: Icons.people_outline,
              title: 'No faculties yet',
              subtitle:
                  'Faculty profiles will appear here once they are added.',
            );
          }

          if (faculties.isEmpty) {
            return _message(
              icon: Icons.search_off,
              title: 'No match for "$_query"',
              subtitle: 'Try a different name.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => speakerProvider.refresh(),
            backgroundColor: AppTheme.background,
            color: AppTheme.primary,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: faculties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final speaker = faculties[index];
                return _FacultyProfile(
                  speaker: speaker,
                  episodes: videoProvider.videosForSpeaker(speaker.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool _matches(SpeakerModel speaker, String query) {
    final needle = query.toLowerCase();
    return speaker.name.toLowerCase().contains(needle) ||
        speaker.designation.toLowerCase().contains(needle);
  }

  Widget _message({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFonts.bold(color: AppTheme.textPrimary, fontSize: 17),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppFonts.regular(
                  color: AppTheme.textMuted,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }
}

/// A single faculty member: portrait, role, about, and their episodes.
class _FacultyProfile extends StatelessWidget {
  const _FacultyProfile({required this.speaker, required this.episodes});

  final SpeakerModel speaker;
  final List<VideoModel> episodes;

  static const double _photoHeight = 320;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
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
                      color: AppTheme.textPrimary,
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
    return SizedBox(
      height: _photoHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (speaker.avatarUrl != null)
            CachedNetworkImage(
              imageUrl: speaker.avatarUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppTheme.surfaceAlt),
              errorWidget: (_, __, ___) => _initials(),
            )
          else
            _initials(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xE6000000)],
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.bold(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.2,
                  ),
                ),
                if (episodes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${episodes.length} episode${episodes.length == 1 ? '' : 's'}',
                    style: AppFonts.semiBold(
                      color: Colors.white70,
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

  Widget _initials() {
    final initials = speaker.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        // runes so a multi-byte first character survives intact
        .map((part) => String.fromCharCode(part.runes.first).toUpperCase())
        .join();

    return Container(
      color: AppTheme.primarySoft,
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: AppFonts.bold(color: AppTheme.primary, fontSize: 44),
      ),
    );
  }

  Widget _episodeSummary(BuildContext context) {
    if (episodes.isEmpty) {
      return Text(
        'No episodes published yet.',
        style: AppFonts.regular(color: AppTheme.textMuted, fontSize: 13.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EPISODES',
          style: AppFonts.bold(
            color: AppTheme.textMuted,
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  onTap: () => VideoReelsScreen.open(
                    context,
                    episodes,
                    initialIndex: episodes.indexOf(episode),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            episode.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.regular(
                              color: AppTheme.textPrimary,
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
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              textStyle: AppFonts.bold(fontSize: 14),
            ),
            onPressed: () => VideoReelsScreen.open(context, episodes),
            child: Text(
              'Watch all ${episodes.length} episode'
              '${episodes.length == 1 ? '' : 's'}',
            ),
          ),
        ),
      ],
    );
  }
}
