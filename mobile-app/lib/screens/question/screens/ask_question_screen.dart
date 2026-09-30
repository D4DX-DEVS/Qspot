import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_client.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/info_note_card.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../auth/widgets/gradient_pill_button.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../../speaker/provider/speaker_provider.dart';
import '../provider/ask_question_screen_provider.dart';
import '../../speaker/model/speaker_model.dart';
import 'my_questions_screen.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  /// Opens the form as a modal sheet over whatever screen the student is on.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
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

  final AskQuestionScreenProvider _state = AskQuestionScreenProvider();

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Burgundy home theme; the sheet reads colours from the context inside it.
    return HomeThemeScope(
      child: ChangeNotifierProvider.value(
        value: _state,
        child: Consumer<AskQuestionScreenProvider>(
          builder: (context, state, _) => _buildPage(context, state),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, AskQuestionScreenProvider state) {
    final p = HomePalette.of(context);
    OutlineInputBorder fieldBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.86,
      child: Container(
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _sheetHeader(context, p),
              Expanded(
                child: Consumer<SpeakerProvider>(
                  builder: (context, speakerProvider, child) {
                    if (speakerProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (speakerProvider.speakers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.paddingLarge),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SoftIconTile(
                                icon: Icons.people_outline,
                                tone: p.rose,
                                size: 84,
                                circle: true,
                              ),
                              const SizedBox(height: AppTheme.paddingMedium),
                              Text(
                                'No Faculties Available',
                                style: AppFonts.bold(
                                  color: p.text,
                                  fontSize: 19,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppTheme.paddingSmall),
                              Text(
                                'Please check back later',
                                style: AppFonts.regular(
                                  color: p.textMuted,
                                  fontSize: 14,
                                ),
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
                            InfoNoteCard(
                              icon: Icons.info_outline,
                              tone: p.rose,
                              message:
                                  'Ask questions to our faculties and get answers',
                            ),

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Faculty Selection
                            Text(
                              'Select Faculty',
                              style: AppFonts.semiBold(
                                color: p.text,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppTheme.paddingSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.paddingMedium,
                              ),
                              decoration: BoxDecoration(
                                color: p.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: p.cardBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<SpeakerModel>(
                                  isExpanded: true,
                                  value: state.selectedFaculty,
                                  hint: Text(
                                    'Choose a faculty',
                                    style: AppFonts.regular(color: p.textMuted),
                                  ),
                                  dropdownColor: p.card,
                                  borderRadius: BorderRadius.circular(16),
                                  style: AppFonts.regular(
                                    color: p.text,
                                    fontSize: 16,
                                  ),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: p.textMuted,
                                  ),
                                  items: speakerProvider.speakers.map((
                                    speaker,
                                  ) {
                                    return DropdownMenuItem<SpeakerModel>(
                                      value: speaker,
                                      child: Text(
                                        speaker.name,
                                        style: AppFonts.regular(
                                          color: p.text,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: state.selectFaculty,
                                ),
                              ),
                            ),

                            const SizedBox(height: AppTheme.paddingLarge),

                            // Subject Field
                            Text(
                              'Subject',
                              style: AppFonts.semiBold(
                                color: p.text,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppTheme.paddingSmall),
                            TextFormField(
                              controller: _subjectController,
                              cursorColor: p.brand,
                              style: AppFonts.regular(
                                color: p.text,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter subject',
                                hintStyle: AppFonts.regular(color: p.textMuted),
                                filled: true,
                                fillColor: p.card,
                                border: fieldBorder(p.cardBorder),
                                enabledBorder: fieldBorder(p.cardBorder),
                                focusedBorder: fieldBorder(p.brand, 1.6),
                                errorBorder: fieldBorder(p.error),
                                focusedErrorBorder: fieldBorder(p.error, 1.6),
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
                            Text(
                              'Your Question',
                              style: AppFonts.semiBold(
                                color: p.text,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppTheme.paddingSmall),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 8,
                              cursorColor: p.brand,
                              style: AppFonts.regular(
                                color: p.text,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Enter your question here in detail...',
                                hintStyle: AppFonts.regular(color: p.textMuted),
                                filled: true,
                                fillColor: p.card,
                                border: fieldBorder(p.cardBorder),
                                enabledBorder: fieldBorder(p.cardBorder),
                                focusedBorder: fieldBorder(p.brand, 1.6),
                                errorBorder: fieldBorder(p.error),
                                focusedErrorBorder: fieldBorder(p.error, 1.6),
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

                            SizedBox(
                              width: double.infinity,
                              child: GradientPillButton(
                                label: 'Submit Question',
                                onPressed: _submitQuestion,
                                isLoading: state.isSubmitting,
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
  Widget _sheetHeader(BuildContext context, HomePalette p) {
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
                decoration: BoxDecoration(
                  color: p.brandSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: p.text, size: 20),
              ),
            ),
          ),
          Text(
            'Ask a question',
            style: AppFonts.bold(color: p.text, fontSize: 17),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.history, color: p.textMuted),
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
    if (_state.selectedFaculty == null) {
      AppSnackBar.show(
        context,
        message: 'Please choose a faculty to send your question to',
        color: AppColors.warningOrange,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _state.startSubmitting();

      try {
        await _state.submit(
          subject: _subjectController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        if (mounted) {
          // Clear the form
          _subjectController.clear();
          _descriptionController.clear();
          _state.finishSubmitting(clearFaculty: true);

          AppSnackBar.show(
            context,
            message: 'Your question has been sent to the faculty',
            color: AppColors.success,
          );
        }
      } catch (e) {
        final message = e is ApiException
            ? e.message
            : 'We couldn\'t send your question. Please try again.';
        if (mounted) {
          _state.finishSubmitting();
          AppSnackBar.show(context, message: message, color: AppColors.danger);
        }
      }
    }
  }
}
