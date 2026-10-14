/// Whether to ask a learner to choose their courses: they have chosen none and
/// the lessons list came back empty. A learner who already has lessons is
/// never asked, even if the saved profile on the phone is out of date.
bool needsCourseChoice({
  required Iterable<String> courseIds,
  required bool listsEmpty,
}) => courseIds.isEmpty && listsEmpty;
