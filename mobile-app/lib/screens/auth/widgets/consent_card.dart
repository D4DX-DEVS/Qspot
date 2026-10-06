import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/auth_theme.dart';
import '../../../widgets/animation/pop_on_change.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/animation/staggered_entrance.dart';
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
            PressableScale(
              pressedScale: 0.98,
              child: CheckboxListTile(
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
                secondary: PopOnChange(
                  active: value,
                  child: Icon(
                    LucideIcons.shieldCheck,
                    size: 30,
                    color: colors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            if (value) ...[
              StaggeredEntrance(
                rise: 10,
                child: RadioGroup<String>(
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
              ),
              StaggeredEntrance(
                index: 1,
                rise: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                  child: AuthTextField(
                    controller: nameController,
                    hint: consentBy == 'parent'
                        ? "Parent/Guardian's Name"
                        : 'School Name',
                    validator: (value) {
                      if (!this.value) return null;
                      if (value == null || value.trim().isEmpty) {
                        return consentBy == 'parent'
                            ? 'Please enter the parent/guardian name'
                            : 'Please enter the school name';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
