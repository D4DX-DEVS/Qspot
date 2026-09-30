import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/subject_model.dart';
import '../provider/subject_provider.dart';
import '../widgets/learn_banner_art.dart';
import '../widgets/subject_card.dart';
import '../widgets/subject_search_delegate.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/common/banner_headline.dart';
import '../../../widgets/common/circle_icon_action.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/gradient_card.dart';
import 'subject_videos_screen.dart';
import '../../video/provider/video_provider.dart';

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
        centerTitle: false,
        actions: [
          CircleIconAction(
            icon: Icons.search_rounded,
            tooltip: 'Search subjects',
            onPressed: _openSearch,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer2<SubjectProvider, VideoProvider>(
        builder: (context, subjectProvider, videoProvider, child) {
          if (subjectProvider.isLoading) {
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
                      Icons.error_outline,
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
                      Icons.book_outlined,
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

          return RefreshIndicator(
            onRefresh: () => subjectProvider.refresh(),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                AppTheme.paddingMedium,
                AppTheme.paddingSmall,
                AppTheme.paddingMedium,
                AppTheme.paddingMedium + MediaQuery.paddingOf(context).bottom,
              ),
              // The banner sits above the course groups.
              itemCount: groups.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _banner();
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
                          child: Text(
                            '${group.course.title} course',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppTheme.paddingMedium,
                              mainAxisSpacing: AppTheme.paddingMedium,
                              childAspectRatio: 0.75, // 120x160 aspect ratio
                            ),
                        itemCount: group.subjects.length,
                        itemBuilder: (context, index) {
                          final subject = group.subjects[index];
                          final lessons = videoProvider
                              .videosForSubject(subject.id)
                              .where((video) => !video.isUpcoming)
                              .toList();
                          final completed = lessons
                              .where(
                                (video) =>
                                    videoProvider
                                        .progressFor(video.id)
                                        ?.completed ==
                                    true,
                              )
                              .length;
                          return SubjectCard(
                            subject: subject,
                            completedLessons: completed,
                            totalLessons: lessons.length,
                            onTap: () => _navigateToSubjectVideos(subject),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
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
        builder: (context) => SubjectVideosScreen(subject: subject),
      ),
    );
  }
}
