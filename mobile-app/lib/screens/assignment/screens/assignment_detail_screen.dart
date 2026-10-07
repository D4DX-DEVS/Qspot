import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/assignment/provider/assignment_detail_provider.dart';
import 'package:qspot/screens/assignment/service/assignment_service.dart';
import 'package:qspot/screens/auth/widgets/gradient_pill_button.dart';
import 'package:qspot/screens/common/widgets/home_theme_scope.dart';
import 'package:qspot/themes/app_colors.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/themes/app_fonts.dart';
import 'package:qspot/themes/app_theme.dart';
import 'package:qspot/themes/home_palette.dart';
import 'package:qspot/widgets/animation/pressable_scale.dart';
import 'package:qspot/widgets/animation/staggered_entrance.dart';
import 'package:qspot/widgets/common/app_snack_bar.dart';
import 'package:qspot/widgets/common/common_app_bar.dart';
import 'package:qspot/widgets/common/info_note_card.dart';
import 'package:qspot/widgets/common/surface_card.dart';
import 'package:qspot/widgets/common/tone_chip.dart';

class AssignmentDetailScreen extends StatefulWidget {
  const AssignmentDetailScreen({super.key, required this.assignment});
  final AssignmentModel assignment;

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  late final TextEditingController _submissionController;
  late final AssignmentDetailProvider _detail;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _submissionController = TextEditingController(
      text: widget.assignment.submissionText,
    );
    _detail = AssignmentDetailProvider(widget.assignment);
  }

  @override
  void dispose() {
    _submissionController.dispose();
    _detail.dispose();
    super.dispose();
  }

  Future<void> _submit(AssignmentModel assignment) async {
    final text = _submissionController.text.trim();
    if (text.isEmpty && _detail.attachments.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Please write your answer or attach a file before submitting',
        color: AppColors.warningOrange,
      );
      return;
    }
    _detail.setSubmitting(true);
    try {
      await AssignmentService.submit(
        assignment.id,
        text: text,
        attachments: _detail.attachments,
      );
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Your assignment has been submitted',
        color: AppColors.success,
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: error is ApiException
            ? error.message
            : 'We couldn\'t submit your assignment. Please try again.',
        color: AppColors.danger,
      );
    } finally {
      if (mounted) _detail.setSubmitting(false);
    }
  }

  bool _allows(AssignmentModel assignment, String mimePrefix) {
    if (assignment.allowedMimeTypes.isEmpty) return true;
    return assignment.allowedMimeTypes.any(
      (mime) => mime == mimePrefix || mime.startsWith('$mimePrefix/'),
    );
  }

  Future<void> _pickAudio(AssignmentModel assignment) async {
    if (!_allows(assignment, 'audio')) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'webm'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      AppSnackBar.show(
        context,
        message: 'We couldn\'t open that audio file. Please try another one.',
        color: AppColors.danger,
      );
      return;
    }
    final mime = _audioMime(file.extension);
    _addAttachment(
      assignment,
      AssignmentUpload(name: file.name, bytes: bytes, mimeType: mime),
    );
  }

  Future<void> _pickPhoto(
    AssignmentModel assignment,
    ImageSource source,
  ) async {
    if (!_allows(assignment, 'image')) return;
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (!mounted || file == null) return;
    final bytes = await file.readAsBytes();
    _addAttachment(
      assignment,
      AssignmentUpload(
        name: file.name,
        bytes: bytes,
        mimeType: _imageMime(file.name),
      ),
    );
  }

  void _addAttachment(AssignmentModel assignment, AssignmentUpload file) {
    if (file.bytes.length > assignment.maxFileSizeBytes) {
      AppSnackBar.show(
        context,
        message:
            '${file.name} is too big. Please choose a file under ${(assignment.maxFileSizeBytes / (1024 * 1024)).ceil()} MB.',
        color: AppColors.warningOrange,
      );
      return;
    }
    _detail.addAttachment(file);
  }

  static String _audioMime(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'webm':
        return 'audio/webm';
      default:
        return 'audio/mpeg';
    }
  }

  static String _imageMime(String name) {
    final extension = name.split('.').last.toLowerCase();
    return extension == 'png' ? 'image/png' : 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(
      child: ChangeNotifierProvider.value(
        value: _detail,
        child: Consumer<AssignmentDetailProvider>(
          builder: (context, detail, _) => _buildPage(context, detail),
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    AssignmentDetailProvider detail,
  ) => Scaffold(
    appBar: const CommonAppBar(title: 'Assignment'),
    body: FutureBuilder<AssignmentModel>(
      future: detail.assignment,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final p = HomePalette.of(context);
        final assignment = snapshot.data ?? widget.assignment;
        final submitted = assignment.isSubmitted;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.contentInset,
            AppTheme.paddingMedium,
            AppTheme.contentInset,
            32 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            StaggeredEntrance(
              child: Text(
                assignment.title,
                style: AppFonts.extraBold(color: p.text, fontSize: 22),
              ),
            ),
            if (assignment.subject.isNotEmpty) ...[
              const SizedBox(height: 6),
              StaggeredEntrance(
                index: 1,
                child: Text(
                  assignment.subject,
                  style: AppFonts.regular(color: p.textMuted, fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 14),
            StaggeredEntrance(
              index: 2,
              child: _DetailMeta(assignment: assignment),
            ),
            if (assignment.instructions.isNotEmpty) ...[
              const SizedBox(height: AppTheme.sectionGap),
              StaggeredEntrance(
                index: 3,
                child: _SectionLabel('What to Do', palette: p),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              StaggeredEntrance(
                index: 3,
                child: SurfaceCard(
                  child: Text(
                    assignment.instructions,
                    style: AppFonts.regular(
                      color: p.text,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.sectionGap),
            if (assignment.feedback.isNotEmpty) ...[
              StaggeredEntrance(
                index: 4,
                child: SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teacher Feedback',
                        style: AppFonts.bold(color: p.text, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        assignment.feedback,
                        style: AppFonts.regular(color: p.text, height: 1.5),
                      ),
                      if (assignment.grade != null) ...[
                        const SizedBox(height: 10),
                        ToneChip(
                          label: 'Score: ${assignment.grade}',
                          tone: p.mint,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (submitted)
              StaggeredEntrance(
                index: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoNoteCard(
                      icon: LucideIcons.circleCheck,
                      tone: p.mint,
                      message: 'Your work has been sent to your teacher.',
                    ),
                    if (assignment.submissionFiles.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.sectionGap),
                      _SectionLabel('Attachments', palette: p),
                      ...assignment.submissionFiles.map(
                        (file) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            file.mimeType.startsWith('audio')
                                ? LucideIcons.music
                                : LucideIcons.image,
                            color: p.brand,
                          ),
                          title: Text(
                            file.name,
                            style: AppFonts.medium(color: p.text),
                          ),
                          subtitle: Text(
                            file.mimeType,
                            style: AppFonts.regular(
                              color: p.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else ...[
              StaggeredEntrance(
                index: 5,
                child: _SectionLabel('Your Answer', palette: p),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              StaggeredEntrance(
                index: 5,
                child: TextField(
                  controller: _submissionController,
                  minLines: 5,
                  maxLines: 9,
                  maxLength: 5000,
                  cursorColor: p.brand,
                  style: AppFonts.regular(color: p.text, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Share Your Answer Here',
                    hintStyle: AppFonts.regular(color: p.textMuted),
                    counterStyle: AppFonts.regular(
                      color: p.textMuted,
                      fontSize: 12,
                    ),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: p.card,
                    border: _fieldBorder(p.cardBorder),
                    enabledBorder: _fieldBorder(p.cardBorder),
                    focusedBorder: _fieldBorder(p.brand, 1.6),
                    contentPadding: const EdgeInsets.all(
                      AppTheme.paddingMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              StaggeredEntrance(
                index: 6,
                child: _AttachmentActions(
                  audioEnabled: _allows(assignment, 'audio'),
                  imageEnabled: _allows(assignment, 'image'),
                  onAudio: () => _pickAudio(assignment),
                  onCamera: () => _pickPhoto(assignment, ImageSource.camera),
                  onGallery: () => _pickPhoto(assignment, ImageSource.gallery),
                ),
              ),
              if (detail.attachments.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...detail.attachments.asMap().entries.map(
                  (entry) => StaggeredEntrance(
                    key: ObjectKey(entry.value),
                    child: _PendingAttachment(
                      file: entry.value,
                      onRemove: () => detail.removeAttachmentAt(entry.key),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.sectionGap),
              StaggeredEntrance(
                index: 7,
                child: GradientPillButton(
                  label: 'Submit Assignment',
                  onPressed: () => _submit(assignment),
                  isLoading: detail.submitting,
                ),
              ),
              const SizedBox(height: 14),
              StaggeredEntrance(
                index: 8,
                child: Text(
                  'Add a voice recording or photo with your answer. You can attach up to 10 files.',
                  style: AppFonts.regular(
                    color: p.textMuted,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );
      },
    ),
  );

  static OutlineInputBorder _fieldBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.palette});

  final String text;
  final HomePalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.semiBold(color: palette.text, fontSize: 16),
    );
  }
}

class _AttachmentActions extends StatelessWidget {
  const _AttachmentActions({
    required this.audioEnabled,
    required this.imageEnabled,
    required this.onAudio,
    required this.onCamera,
    required this.onGallery,
  });

  final bool audioEnabled;
  final bool imageEnabled;
  final VoidCallback onAudio;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final style = OutlinedButton.styleFrom(
      foregroundColor: p.brand,
      backgroundColor: p.card,
      disabledForegroundColor: p.textMuted,
      side: BorderSide(color: p.cardBorder),
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      textStyle: AppFonts.semiBold(fontSize: 14.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PressableScale(
          enabled: audioEnabled,
          child: OutlinedButton.icon(
            onPressed: audioEnabled ? onAudio : null,
            icon: const Icon(LucideIcons.fileAudio, size: 19),
            label: const Text('Upload Audio'),
            style: style,
          ),
        ),
        PressableScale(
          enabled: imageEnabled,
          child: OutlinedButton.icon(
            onPressed: imageEnabled ? onCamera : null,
            icon: const Icon(LucideIcons.camera, size: 19),
            label: const Text('Take Photo'),
            style: style,
          ),
        ),
        PressableScale(
          enabled: imageEnabled,
          child: OutlinedButton.icon(
            onPressed: imageEnabled ? onGallery : null,
            icon: const Icon(LucideIcons.images, size: 19),
            label: const Text('Choose Photo'),
            style: style,
          ),
        ),
      ],
    );
  }
}

class _PendingAttachment extends StatelessWidget {
  const _PendingAttachment({required this.file, required this.onRemove});

  final AssignmentUpload file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        file.mimeType.startsWith('audio')
            ? LucideIcons.music
            : LucideIcons.image,
        color: p.brand,
      ),
      title: Text(file.name, style: AppFonts.medium(color: p.text)),
      subtitle: Text(
        '${(file.bytes.length / 1024).ceil()} KB',
        style: AppFonts.regular(color: p.textMuted, fontSize: 12),
      ),
      trailing: IconButton(
        tooltip: 'Remove Attachment',
        onPressed: onRemove,
        icon: Icon(LucideIcons.x, color: p.textMuted),
      ),
    );
  }
}

class _DetailMeta extends StatelessWidget {
  const _DetailMeta({required this.assignment});
  final AssignmentModel assignment;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final tone = assignment.isSubmitted
        ? p.mint
        : assignment.isOverdue
        ? p.coral
        : p.rose;
    final status = assignment.isSubmitted
        ? 'Submitted'
        : assignment.isOverdue
        ? 'Past Due'
        : 'To Do';
    final due = assignment.dueAt == null
        ? 'No Due Date'
        : 'Due ${assignment.dueAt!.toLocal().day}/${assignment.dueAt!.toLocal().month}/${assignment.dueAt!.toLocal().year}';
    final dueColor = assignment.isOverdue ? p.error : p.textMuted;
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ToneChip(label: status, tone: tone),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarDays, size: 16, color: dueColor),
            const SizedBox(width: 4),
            Text(due, style: AppFonts.regular(color: dueColor, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
