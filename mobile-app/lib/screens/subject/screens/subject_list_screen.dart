import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/subject_model.dart';
import '../provider/subject_provider.dart';
import '../widgets/subject_card.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/common/common_app_bar.dart';
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CommonAppBar(title: 'Learn'),
      body: Consumer2<SubjectProvider, VideoProvider>(
        builder: (context, subjectProvider, videoProvider, child) {
          if (subjectProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.gradientEnd),
            );
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
                      color: AppTheme.secondaryGray,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      'Error Loading Subjects',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      subjectProvider.errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryGray,
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
                      color: AppTheme.secondaryGray,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      'No Subjects Available',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      'Check back later for new subjects',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryGray,
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
            backgroundColor: AppTheme.surface,
            color: AppTheme.primary,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                AppTheme.paddingMedium,
                AppTheme.paddingMedium,
                AppTheme.paddingMedium,
                AppTheme.paddingMedium + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: groups.length,
              itemBuilder: (context, groupIndex) {
                final group = groups[groupIndex];
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
                                  color: AppTheme.textPrimary,
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

  void _navigateToSubjectVideos(SubjectModel subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectVideosScreen(subject: subject),
      ),
    );
  }
}
