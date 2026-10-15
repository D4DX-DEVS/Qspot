import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../themes/home_theme.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/nav_list_card.dart';
import '../model/subject_model.dart';
import '../provider/subject_provider.dart';

/// Full-screen subject search for the Learn tab. Matching is done by
/// [SubjectProvider.searchSubjects]; tapping a result calls [onSelected].
class SubjectSearchDelegate extends SearchDelegate<void> {
  SubjectSearchDelegate({required this.onSelected})
    : super(searchFieldLabel: 'Search Subjects');

  final ValueChanged<SubjectModel> onSelected;

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = HomeTheme.of(MediaQuery.platformBrightnessOf(context));
    return theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: AppFonts.regular(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Clear',
        onPressed: () => query = '',
        icon: const Icon(LucideIcons.x),
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: 'Back',
    onPressed: () => close(context, null),
    icon: const Icon(LucideIcons.arrowLeft),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final palette = HomePalette.of(context);
    final matches = context.watch<SubjectProvider>().searchSubjects(
      query.trim(),
    );
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No Subjects Match "${query.trim()}"',
            textAlign: TextAlign.center,
            style: AppFonts.regular(color: palette.textMuted, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => StaggeredEntrance(
        index: index,
        child: NavListCard(
          icon: LucideIcons.bookOpen,
          tone: index.isEven ? palette.teal : palette.coral,
          title: matches[index].displayName,
          subtitle: 'Open Chapter',
          onTap: () => onSelected(matches[index]),
        ),
      ),
    );
  }
}
