import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/auth_theme.dart';
import 'auth_text_field.dart';

/// Consent tick box. Once ticked it asks who gave consent (parent or
/// school) and their name.
class ConsentCard extends StatelessWidget {
  const ConsentCard({
    super.key,
    required this.value,
    required this.onChanged,
    required this.consentBy,
    required this.onConsentByChanged,
    required this.nameController,
    this.label = 'A parent/guardian or school has given consent',
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  /// 'parent' or 'school', as the API expects.
  final String consentBy;
  final ValueChanged<String> onConsentByChanged;
  final TextEditingController nameController;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AuthTheme.fieldRadius),
        side: BorderSide(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              value: value,
              onChanged: (checked) => onChanged(checked ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                label,
                style: AppFonts.regular(
                  color: colors.onSurface,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              secondary: Icon(
                Icons.verified_user_rounded,
                size: 30,
                color: colors.primary.withValues(alpha: 0.3),
              ),
            ),
            if (value) ...[
              RadioGroup<String>(
                groupValue: consentBy,
                onChanged: (by) => onConsentByChanged(by ?? 'parent'),
                child: Row(
                  children: [
                    for (final option in const ['parent', 'school'])
                      Expanded(
                        child: RadioListTile<String>(
                          value: option,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            option == 'parent' ? 'Parent' : 'School',
                            style: AppFonts.regular(
                              color: colors.onSurface,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                child: AuthTextField(
                  controller: nameController,
                  hint: consentBy == 'parent'
                      ? "Parent/guardian's name"
                      : 'School name',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
