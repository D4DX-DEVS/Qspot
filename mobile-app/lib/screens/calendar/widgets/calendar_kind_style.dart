import '../../../themes/accent_tone.dart';
import '../../../themes/home_palette.dart';
import '../model/calendar_event_kind.dart';

/// The colour each kind of entry wears, on its dot and its chip.
extension CalendarKindStyle on CalendarEventKind {
  AccentTone tone(HomePalette palette) => switch (this) {
    CalendarEventKind.assignment => palette.amber,
    CalendarEventKind.quiz => palette.coral,
    CalendarEventKind.liveClass => palette.teal,
    CalendarEventKind.lesson => palette.mint,
  };
}
