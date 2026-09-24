import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_client.dart';
import '../../../themes/app_theme.dart';
import '../../speaker/provider/speaker_provider.dart';
import '../model/question_model.dart';
import '../../speaker/model/speaker_model.dart';
import '../service/question_service.dart';
import 'my_questions_screen.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  /// Opens the form as a modal sheet over whatever screen the student is on.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AskQuestionScreen(),
    );
  }

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  SpeakerModel? _selectedFaculty;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.86,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _sheetHeader(context),
              Expanded(
                child: Consumer<SpeakerProvider>(
                  builder: (context, speakerProvider, child) {
                    if (speakerProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.gradientEnd,
                        ),
                      );
                    }

                    if (speakerProvider.speakers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.paddingLarge),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppTheme.secondaryGray,
                              ),
                              const SizedBox(height: AppTheme.paddingMedium),
                              Text(
                                'No Faculties Available',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(color: AppTheme.textPrimary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppTheme.paddingSmall),
                              Text(
                                'Please check back later',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.secondaryGray),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.paddingMedium),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info Card
                            Container(
                              padding: const EdgeInsets.all(
                                AppTheme.paddingMedium,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySoft,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                                border: Border.all(
                                  color: AppTheme.border,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.gradientEnd,
                                    size: 24,
                                  ),
                                  const SizedBox(width: AppTheme.paddingSmall),
                                  Expanded(
                                    child: Text(
                                      'Ask questions to our faculties and get answers',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Faculty Selection
                            const Text(
                              'Select Faculty',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppTheme.paddingSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.paddingMedium,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                                border: Border.all(
                                  color: AppTheme.border,
                                  width: 1,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<SpeakerModel>(
                                  isExpanded: true,
                                  value: _selectedFaculty,
                                  hint: const Text(
                                    'Choose a faculty',
                                    style: TextStyle(
                                      color: AppTheme.secondaryGray,
                                    ),
                                  ),
                                  dropdownColor: AppTheme.background,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                  ),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: AppTheme.secondaryGray,
                                  ),
                                  items: speakerProvider.speakers.map((
                                    speaker,
                                  ) {
                                    return DropdownMenuItem<SpeakerModel>(
                                      value: speaker,
                                      child: Text(
                                        speaker.name,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (SpeakerModel? newValue) {
                                    setState(() {
                                      _selectedFaculty = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Subject Field
                            const Text(
                              'Subject',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppTheme.paddingSmall),
                            TextFormField(
                              controller: _subjectController,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter subject',
                                hintStyle: TextStyle(
                                  color: AppTheme.secondaryGray,
                                ),
                                filled: true,
                                fillColor: AppTheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: const BorderSide(
                                    color: AppTheme.gradientEnd,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(
                                  AppTheme.paddingMedium,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a subject';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Description Field
                            const Text(
                              'Your Question',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppTheme.paddingSmall),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 8,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Enter your question here in detail...',
                                hintStyle: TextStyle(
                                  color: AppTheme.secondaryGray,
                                ),
                                filled: true,
                                fillColor: AppTheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: const BorderSide(
                                    color: AppTheme.gradientEnd,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(
                                  AppTheme.paddingMedium,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your question';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _submitQuestion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.gradientStart,
                                  foregroundColor: AppTheme.onPrimary,
                                  disabledBackgroundColor: AppTheme.surfaceAlt,
                                  disabledForegroundColor: AppTheme.textMuted,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: AppTheme.onPrimary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Submit Question',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
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
            ],
          ),
        ),
      ),
    );
  }

  /// Close on the left, centred title, "my questions" on the right — the same
  /// header shape as the reference app's popups.
  Widget _sheetHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Stack(
        alignment: Alignment.center,
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
                  color: AppTheme.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          const Text(
            'Ask a question',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.history, color: AppTheme.textMuted),
              tooltip: 'My questions',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyQuestionsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuestion() async {
    if (_selectedFaculty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a faculty',
            style: TextStyle(color: AppTheme.onPrimary),
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final question = QuestionModel(
          subject: _subjectController.text.trim(),
          description: _descriptionController.text.trim(),
          faculty: _selectedFaculty!.id,
        );

        await QuestionService.submit(question);

        if (mounted) {
          // Clear the form
          _subjectController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedFaculty = null;
            _isSubmitting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Question submitted successfully!',
                style: TextStyle(color: AppTheme.onPrimary),
              ),
              backgroundColor: AppTheme.gradientStart,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        final message = e is ApiException
            ? e.message
            : 'Failed to submit question';
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: const TextStyle(color: AppTheme.onPrimary),
              ),
              backgroundColor: AppTheme.danger,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
