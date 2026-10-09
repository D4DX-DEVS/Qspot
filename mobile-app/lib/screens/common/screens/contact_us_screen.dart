import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../utils/address_maps.dart';
import '../../../utils/feedback_mail.dart';
import '../../../utils/phone_dialer.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/info_note_card.dart';
import '../../settings/widgets/settings_group_card.dart';
import '../../settings/widgets/settings_row.dart';
import '../widgets/home_theme_scope.dart';

enum _PhoneContactAction { call, whatsapp }

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const _phoneNumber = '+91 98959 89800';

  Future<void> _showPhoneActions(BuildContext context) async {
    final p = HomePalette.of(context);
    final action = await showModalBottomSheet<_PhoneContactAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: p.card,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(LucideIcons.phone, color: p.brand),
                title: const Text('Call us'),
                subtitle: const Text(_phoneNumber),
                onTap: () =>
                    Navigator.pop(sheetContext, _PhoneContactAction.call),
              ),
              ListTile(
                leading: Icon(LucideIcons.messageCircle, color: p.teal.color),
                title: const Text('Message on WhatsApp'),
                subtitle: const Text('Open a WhatsApp chat'),
                onTap: () =>
                    Navigator.pop(sheetContext, _PhoneContactAction.whatsapp),
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case _PhoneContactAction.call:
        await callPhone(context, _phoneNumber);
      case _PhoneContactAction.whatsapp:
        await messageOnWhatsApp(context, _phoneNumber);
    }
  }

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
                  subtitle: '$_phoneNumber · Call or WhatsApp',
                  onTap: () => _showPhoneActions(context),
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
                  onTap: () => openD4dxAddress(context),
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
