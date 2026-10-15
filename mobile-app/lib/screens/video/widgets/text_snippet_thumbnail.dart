import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../provider/text_preview_provider.dart';

/// The first lines of a text file, drawn small like a page. Shows
/// [placeholder] while loading or when the file can't be read.
class TextSnippetThumbnail extends StatelessWidget {
  const TextSnippetThumbnail({
    super.key,
    required this.url,
    required this.placeholder,
  });

  final String url;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // A new file gets a fresh provider instead of the old file's snippet.
      key: ValueKey(url),
      create: (_) => TextPreviewProvider(url)..load(),
      child: Consumer<TextPreviewProvider>(
        builder: (context, preview, _) {
          final snippet = preview.snippet;
          if (snippet == null) return placeholder;
          final p = HomePalette.of(context);
          // Decorative; the card's title is what screen readers announce.
          return ExcludeSemantics(
            child: ColoredBox(
              color: p.card,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  snippet,
                  overflow: TextOverflow.clip,
                  textScaler: TextScaler.noScaling,
                  style: AppFonts.regular(
                    color: p.textMuted,
                    fontSize: 5.5,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
