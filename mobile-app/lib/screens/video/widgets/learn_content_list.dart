import 'package:flutter/material.dart';

import '../model/video_model.dart';
import 'learn_note_body.dart';

/// Scrollable Learn note and key points. Files live in the Downloads tab.
class LearnContentList extends StatelessWidget {
  const LearnContentList({
    super.key,
    required this.video,
    this.padding = const EdgeInsets.all(20),
  });

  final VideoModel video;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: [LearnNoteBody(video: video)],
    );
  }
}
