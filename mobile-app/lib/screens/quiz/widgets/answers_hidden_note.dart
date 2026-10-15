import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/home_palette.dart';
import '../../../widgets/common/info_note_card.dart';
import '../model/answers_availability.dart';

/// Says when the correct answers will show, for a result whose answers the
/// server is still holding back.
class AnswersHiddenNote extends StatelessWidget {
  const AnswersHiddenNote({super.key, required this.availability});

  final AnswersAvailability availability;

  @override
  Widget build(BuildContext context) {
    return InfoNoteCard(
      icon: LucideIcons.clock,
      tone: HomePalette.of(context).slate,
      message: availability.hiddenMessage(),
    );
  }
}
