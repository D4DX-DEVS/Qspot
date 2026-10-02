import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../utils/feedback_mail.dart';
import '../../../utils/phone_dialer.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/info_note_card.dart';
import '../../settings/widgets/settings_group_card.dart';
import '../../settings/widgets/settings_row.dart';
import '../widgets/home_theme_scope.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(child: Builder(builder: _buildPage));
  }

  Widget _buildPage(BuildContext context) {
    final p = HomePalette.of(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Contact Us'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          StaggeredEntrance(
            child: Text(
              'Get in Touch',
              style: AppFonts.extraBold(color: p.text, fontSize: 26),
            ),
          ),
          const SizedBox(height: 4),
          StaggeredEntrance(
            index: 1,
            child: Text(
              "We'd love to hear from you",
              style: AppFonts.regular(color: p.textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          StaggeredEntrance(
            index: 2,
            child: SettingsGroupCard(
              children: [
                SettingsRow(
                  icon: LucideIcons.phone,
                  tone: p.rose,
                  title: 'Phone',
                  subtitle: '+91 98959 89800',
                  onTap: () => callPhone(context, '+91 98959 89800'),
                ),
                SettingsRow(
                  icon: LucideIcons.mail,
                  tone: p.coral,
                  title: 'Email',
                  subtitle: 'mail@d4dx.co',
                  onTap: () => sendFeedbackMail(context),
                ),
                SettingsRow(
                  icon: LucideIcons.mapPin,
                  tone: p.teal,
                  title: 'Address',
                  subtitle:
                      'D4DX Innovations LLP\nMavoor Road, Calicut, Kerala,\nPin 673004',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          StaggeredEntrance(
            index: 3,
            child: InfoNoteCard(
              icon: LucideIcons.info,
              tone: p.rose,
              message:
                  'Stuck, found a bug, or got an idea? Message us. We read everything.',
            ),
          ),
        ],
      ),
    );
  }
}
