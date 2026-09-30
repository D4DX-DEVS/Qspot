import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/api_client.dart';
import '../../../services/video_progress_service.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../model/video_model.dart';
import '../provider/video_questions_screen_provider.dart';

/// The questions attached to a video, asked once the video has been watched.
///
/// Grading happens on the server, so the answers never travel back to the
/// client before the student has committed to them.
class VideoQuestionsScreen extends StatefulWidget {
  const VideoQuestionsScreen({
    super.key,
    required this.videoId,
    required this.videoTitle,
    required this.questions,
    this.locale = 'en',
    this.priorResult,
    this.settings = const VideoPracticeSettings(),
  });

  final String videoId;
  final String videoTitle;
  final List<VideoQuestionItem> questions;
  final String locale;

  /// When the student already has a graded attempt for this video, it is
  /// passed in here and shown read-only — there is no retake once an attempt
  /// exists (see the video-quiz contract: 409 "Already attempted").
  final VideoQuizResult? priorResult;
  final VideoPracticeSettings settings;

  /// Opens Practice for [video]: checks for an existing (graded) attempt
  /// first and shows it read-only when found, otherwise fetches the
  /// questions and lets the student answer them. Gated on `completed` by the
  /// caller (the Practice entry point is disabled until the video is done).
  static Future<void> open(
    BuildContext context,
    VideoModel video, {
    String locale = 'en',
  }) async {
    final prior = await VideoProgressService.existingAttempt(video.id);
    if (!context.mounted) return;

    if (prior != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoQuestionsScreen(
            videoId: video.id,
            videoTitle: video.displayTitle,
            questions: const [],
            locale: locale,
            priorResult: prior,
          ),
        ),
      );
      return;
    }

    final questions = await VideoProgressService.questions(video.id);
    final settings = await VideoProgressService.practiceSettings(video.id);
    if (!context.mounted || questions.isEmpty) return;
    if (!settings.available) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoQuestionsScreen(
          videoId: video.id,
          videoTitle: video.displayTitle,
          questions: questions,
          locale: locale,
          settings: settings,
        ),
      ),
    );
  }

  @override
  State<VideoQuestionsScreen> createState() => _VideoQuestionsScreenState();
}

class _VideoQuestionsScreenState extends State<VideoQuestionsScreen> {
  late final VideoQuestionsScreenProvider _q;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _q = VideoQuestionsScreenProvider(priorResult: widget.priorResult);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isReview) return;
    final mode = widget.settings.timerMode;
    final initial = mode == 'overall' || mode == 'both'
        ? widget.settings.overallTimeLimit
        : (mode == 'per-question' ? widget.settings.perQuestionTimeLimit : null);
    if (initial == null || initial <= 0) return;
    _q.setRemainingSeconds(initial);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _q.remainingSeconds;
      if (!mounted || remaining == null) return;
      if (remaining <= 1) {
        _timer?.cancel();
        _submit();
      } else {
        _q.decrementRemaining();
      }
    });
  }

  void _resetPerQuestionTimer() {
    if (widget.settings.timerMode == 'overall') return;
    final seconds = widget.settings.perQuestionTimeLimit;
    if (seconds != null && seconds > 0) _q.setRemainingSeconds(seconds);
  }

  String _timerLabel(VideoQuestionsScreenProvider q) {
    final seconds = q.remainingSeconds ?? 0;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  bool get _isReview => widget.priorResult != null;
  bool _isLast(VideoQuestionsScreenProvider q) =>
      q.index == widget.questions.length - 1;

  int? _selected(VideoQuestionsScreenProvider q) =>
      q.answerFor(widget.questions[q.index].id);

  void _choose(int optionIndex) {
    _q.choose(widget.questions[_q.index].id, optionIndex);
  }

  Future<void> _next() async {
    if (_selected(_q) == null) return;
    if (!_isLast(_q)) {
      _q.nextQuestion();
      _resetPerQuestionTimer();
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    _q.startSubmit();
    final answers = _q.answersPayload(widget.questions);

    try {
      final result = await VideoProgressService.submit(
        videoId: widget.videoId,
        answers: answers,
        locale: widget.locale,
      );
      if (!mounted) return;
      _q.finishSubmit(result);
    } on ApiException catch (e) {
      // 403 = "watch the video first" (shouldn't normally be reachable —
      // Practice is gated on completed), 409 = already attempted elsewhere
      // (another device, or a double-tap): re-fetch and show that attempt.
      if (e.status == 409) {
        final prior = await VideoProgressService.existingAttempt(
          widget.videoId,
        );
        if (!mounted) return;
        _q.finishSubmit(prior);
        return;
      }
      if (!mounted) return;
      _q.failSubmit(e.message);
    } catch (e) {
      if (!mounted) return;
      _q.failSubmit('Could not save your answers. Please try again.');
    }

    if (_q.submitError != null && mounted) {
      AppSnackBar.show(
        context,
        message: _q.submitError!,
        color: AppColors.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _q,
      child: Consumer<VideoQuestionsScreenProvider>(
        builder: (_, q, __) => _buildPage(q),
      ),
    );
  }

  Widget _buildPage(VideoQuestionsScreenProvider q) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // The result view carries its own close button, like the reference popups.
      appBar: q.result != null
          ? null
          : const CommonAppBar(title: 'Video questions'),
      body: q.result != null ? _buildResult(q) : _buildQuestion(q),
    );
  }

  Widget _buildResult(VideoQuestionsScreenProvider q) {
    final result = q.result!;
    final headline = result.percentage >= 80
        ? 'Way to go!'
        : result.percentage >= 50
        ? 'Nice work!'
        : 'Keep going!';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
            const Spacer(),
            _celebration(result.percentage),
            const SizedBox(height: 28),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: AppFonts.bold(
                fontSize: 26,
                height: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You answered ${result.score} of ${result.totalQuestions} correctly.',
              textAlign: TextAlign.center,
              style: AppFonts.regular(
                fontSize: 16,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.videoTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.regular(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (_isReview) ...[
              const SizedBox(height: 8),
              Text(
                'You already answered these questions — this is your saved result.',
                textAlign: TextAlign.center,
                style: AppFonts.regular(color: AppColors.textMuted, fontSize: 12.5),
              ),
            ],
            const Spacer(),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const StadiumBorder(),
                  textStyle: AppFonts.bold(
                    fontSize: 16,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
            // No retake once an attempt exists — the server rejects it (409)
            // and the contract explicitly forbids offering one.
          ],
        ),
      ),
    );
  }

  /// Trophy in a soft disc with a little confetti — the celebration the
  /// reference app shows when a round finishes.
  Widget _celebration(int percentage) {
    const dots = <List<double>>[
      [8, 16, 8],
      [172, 24, 6],
      [22, 118, 6],
      [176, 112, 8],
      [86, 4, 6],
      [118, 142, 6],
    ];
    const colors = [AppColors.accent, AppColors.accentAmber, AppColors.primary];

    return Center(
      child: SizedBox(
        width: 200,
        height: 168,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < dots.length; i++)
              Positioned(
                left: dots[i][0],
                top: dots[i][1],
                child: Container(
                  width: dots[i][2],
                  height: dots[i][2],
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Container(
              width: 136,
              height: 136,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 46,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$percentage%',
                    style: AppFonts.bold(
                      fontSize: 20,
                      color: AppColors.primary,
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

  Widget _buildQuestion(VideoQuestionsScreenProvider q) {
    if (widget.questions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final question = widget.questions[q.index];
    final options = question.optionsFor(widget.locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.paddingMedium,
            0,
            AppTheme.paddingMedium,
            AppTheme.paddingSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (q.index + 1) / widget.questions.length,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              if (q.remainingSeconds != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Time ${_timerLabel(q)}',
                    style: AppFonts.bold(
                      color: q.remainingSeconds! <= 10 ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                ),
              if (q.remainingSeconds != null) const SizedBox(height: 10),
              Text(
                'Question ${q.index + 1} of ${widget.questions.length}',
                style: AppFonts.medium(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                question.questionFor(widget.locale),
                style: AppFonts.semiBold(
                  fontSize: 18,
                  height: 1.35,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingMedium,
            ),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final selected = _selected(q) == i;
              return InkWell(
                onTap: () => _choose(i),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primarySoft : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: AppFonts.semiBold(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          options[i],
                          style: AppFonts.regular(
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceAlt,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              onPressed: _selected(q) == null || q.submitting ? null : _next,
              child: Text(
                q.submitting
                    ? 'Saving...'
                    : _isLast(q)
                    ? 'Submit'
                    : 'Next',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
