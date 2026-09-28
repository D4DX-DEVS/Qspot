import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/assignment/service/assignment_service.dart';
import 'package:qspot/themes/app_theme.dart';
import 'package:qspot/themes/app_fonts.dart';
import 'package:qspot/widgets/common/common_app_bar.dart';

class AssignmentDetailScreen extends StatefulWidget {
  const AssignmentDetailScreen({super.key, required this.assignment});
  final AssignmentModel assignment;

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  late final TextEditingController _submissionController;
  late Future<AssignmentModel> _assignment;
  bool _submitting = false;
  final List<AssignmentUpload> _attachments = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _submissionController = TextEditingController(
      text: widget.assignment.submissionText,
    );
    _assignment = AssignmentService.fetchOne(
      widget.assignment.id,
    ).catchError((_) => widget.assignment);
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _submit(AssignmentModel assignment) async {
    final text = _submissionController.text.trim();
    if (text.isEmpty && _attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a few words before submitting.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await AssignmentService.submit(
        assignment.id,
        text: text,
        attachments: _attachments,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Assignment submitted')));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not submit: $error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that audio file.')),
      );
      return;
    }
    final mime = _audioMime(file.extension);
    _addAttachment(
      assignment,
      AssignmentUpload(name: file.name, bytes: bytes, mimeType: mime),
    );
  }

  Future<void> _pickPhoto(AssignmentModel assignment, ImageSource source) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${file.name} is larger than ${(assignment.maxFileSizeBytes / (1024 * 1024)).ceil()} MB.',
          ),
        ),
      );
      return;
    }
    setState(() => _attachments.add(file));
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
  Widget build(BuildContext context) => Scaffold(
    appBar: const CommonAppBar(title: 'Assignment'),
    body: FutureBuilder<AssignmentModel>(
      future: _assignment,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final assignment = snapshot.data ?? widget.assignment;
        final submitted = assignment.isSubmitted;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              assignment.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (assignment.subject.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                assignment.subject,
                style: AppFonts.regular(color: AppTheme.textMuted),
              ),
            ],
            const SizedBox(height: 18),
            _DetailMeta(assignment: assignment),
            if (assignment.instructions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'What to do',
                style: AppFonts.bold(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                assignment.instructions,
                style: AppFonts.regular(height: 1.45),
              ),
            ],
            const SizedBox(height: 28),
            if (assignment.feedback.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher feedback',
                      style: AppFonts.bold(),
                    ),
                    const SizedBox(height: 6),
                    Text(assignment.feedback),
                    if (assignment.grade != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Score: ${assignment.grade}',
                        style: AppFonts.bold(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (submitted)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.success),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Your work has been sent to your teacher.'),
                        ),
                      ],
                    ),
                  ),
                  if (assignment.submissionFiles.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Attachments',
                      style: AppFonts.bold(),
                    ),
                    ...assignment.submissionFiles.map(
                      (file) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          file.mimeType.startsWith('audio')
                              ? Icons.audiotrack_outlined
                              : Icons.image_outlined,
                        ),
                        title: Text(file.name),
                        subtitle: Text(file.mimeType),
                      ),
                    ),
                  ],
                ],
              )
            else ...[
              Text(
                'Your answer',
                style: AppFonts.bold(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _submissionController,
                minLines: 5,
                maxLines: 9,
                maxLength: 5000,
                decoration: const InputDecoration(
                  hintText: 'Share your answer here',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              _AttachmentActions(
                audioEnabled: _allows(assignment, 'audio'),
                imageEnabled: _allows(assignment, 'image'),
                onAudio: () => _pickAudio(assignment),
                onCamera: () => _pickPhoto(assignment, ImageSource.camera),
                onGallery: () => _pickPhoto(assignment, ImageSource.gallery),
              ),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 10),
                ..._attachments.asMap().entries.map(
                  (entry) => _PendingAttachment(
                    file: entry.value,
                    onRemove: () => setState(
                      () => _attachments.removeAt(entry.key),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : () => _submit(assignment),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_submitting ? 'Sending...' : 'Submit assignment'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add a voice recording or photo with your answer. You can attach up to 10 files.',
                style: AppFonts.regular(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ],
        );
      },
    ),
  );
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: audioEnabled ? onAudio : null,
          icon: const Icon(Icons.audio_file_outlined),
          label: const Text('Upload audio'),
        ),
        OutlinedButton.icon(
          onPressed: imageEnabled ? onCamera : null,
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Take photo'),
        ),
        OutlinedButton.icon(
          onPressed: imageEnabled ? onGallery : null,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choose photo'),
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
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        file.mimeType.startsWith('audio')
            ? Icons.audiotrack_outlined
            : Icons.image_outlined,
      ),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${(file.bytes.length / 1024).ceil()} KB'),
      trailing: IconButton(
        tooltip: 'Remove attachment',
        onPressed: onRemove,
        icon: const Icon(Icons.close),
      ),
    );
  }
}

class _DetailMeta extends StatelessWidget {
  const _DetailMeta({required this.assignment});
  final AssignmentModel assignment;

  @override
  Widget build(BuildContext context) {
    final statusColor = assignment.isSubmitted
        ? AppTheme.success
        : assignment.isOverdue
        ? AppTheme.danger
        : AppTheme.primary;
    final status = assignment.isSubmitted
        ? 'Submitted'
        : assignment.isOverdue
        ? 'Past due'
        : 'To do';
    final due = assignment.dueAt == null
        ? 'No due date'
        : 'Due ${assignment.dueAt!.toLocal().day}/${assignment.dueAt!.toLocal().month}/${assignment.dueAt!.toLocal().year}';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: AppFonts.bold(
              color: statusColor,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.event_outlined,
          size: 16,
          color: assignment.isOverdue ? AppTheme.danger : AppTheme.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          due,
          style: AppFonts.regular(
            color: assignment.isOverdue ? AppTheme.danger : AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
