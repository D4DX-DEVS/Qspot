import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../model/subject_model.dart';
import '../provider/subject_provider.dart';
import '../widgets/learn_banner_art.dart';
import '../widgets/chapter_class_tile.dart';
import '../widgets/subject_search_delegate.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/adaptive_card_columns.dart';
import '../../../widgets/common/banner_headline.dart';
import '../../../widgets/common/circle_icon_action.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/gradient_card.dart';
import '../../../widgets/common/section_header.dart';
import '../../common/widgets/home_theme_scope.dart';
import 'subject_videos_screen.dart';
import '../../video/provider/video_provider.dart';
import '../../../widgets/common/offline_notice.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subjects = context.read<SubjectProvider>();
      if (subjects.loadingState == SubjectLoadingState.idle) {
        subjects.initialize();
      }
      final videos = context.read<VideoProvider>();
      if (videos.loadingState == VideoLoadingState.idle) {
        videos.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Learn',
        isDrawerNeeded: true,
        actions: [
          CircleIconAction(
            icon: LucideIcons.search,
            tooltip: 'Search Subjects',
            onPressed: _openSearch,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer2<SubjectProvider, VideoProvider>(
        builder: (context, subjectProvider, videoProvider, child) {
          if (subjectProvider.isLoading && subjectProvider.subjects.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (subjectProvider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.circleAlert,
                      size: 64,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      'Error Loading Subjects',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      subjectProvider.errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.paddingLarge),
                    ElevatedButton(
                      onPressed: () => subjectProvider.refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (subjectProvider.subjects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.book,
                      size: 64,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      'No Subjects Available',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      'Check back later for new subjects',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final groups = subjectProvider.groupedByCourse;

          final list = ListView.builder(
            padding: EdgeInsets.fromLTRB(
              AppTheme.paddingMedium,
              AppTheme.paddingSmall,
              AppTheme.paddingMedium,
              AppTheme.paddingMedium + MediaQuery.paddingOf(context).bottom,
            ),
            // The banner sits above the course groups.
            itemCount: groups.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return StaggeredEntrance(child: _banner());
              }
              final groupIndex = index;
              final group = groups[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (group.course.title.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          bottom: AppTheme.paddingSmall,
                        ),
                        child: StaggeredEntrance(
                          index: groupIndex,
                          child: SectionHeader(
                            title: '${group.course.title} Course',
                            subtitle:
                                '${group.subjects.length} Chapter'
                                '${group.subjects.length == 1 ? '' : 's'}',
                          ),
                        ),
                      ),
                    AdaptiveCardColumns(
                      spacing: AppTheme.paddingMedium,
                      children: [
                        for (var i = 0; i < group.subjects.length; i++)
                          StaggeredEntrance(
                            index: groupIndex + i + 1,
                            child: ChapterClassTile(
                              number: i + 1,
                              title: group.subjects[i].displayName,
                              imageUrl: group.subjects[i].imageUrl,
                              progress: videoProvider.chapterProgressFor(
                                group.subjects[i].id,
                              ),
                              onTap: () =>
                                  _navigateToSubjectVideos(group.subjects[i]),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
          return RefreshIndicator(
            onRefresh: () => subjectProvider.refresh(),
            child: Column(
              children: [
                if (subjectProvider.errorMessage.isNotEmpty)
                  OfflineNotice(message: subjectProvider.errorMessage),
                Expanded(child: list),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _banner() {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppTheme.paddingLarge),
      child: GradientCard(
        minHeight: 118,
        artSize: Size(150, 118),
        art: LearnBannerArt(),
        child: BannerHeadline(
          title: 'Explore Subjects',
          subtitle: 'Choose a course and start learning',
          trailingWidth: 120,
        ),
      ),
    );
  }

  void _openSearch() {
    showSearch<void>(
      context: context,
      delegate: SubjectSearchDelegate(onSelected: _navigateToSubjectVideos),
    );
  }

  void _navigateToSubjectVideos(SubjectModel subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HomeThemeScope(child: SubjectVideosScreen(subject: subject)),
      ),
    );
  }
}
