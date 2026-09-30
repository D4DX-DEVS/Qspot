import 'package:flutter/material.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/common/common_app_bar.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'Contact Us'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Title and Subtitle
            Text(
              'Get in Touch',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We'd love to hear from you",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textMuted),
            ),

            const SizedBox(height: 40),

            // Contact Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.gradientDecoration(),
              child: Column(
                children: [
                  // Phone Section
                  _buildContactSection(
                    context: context,
                    icon: Icons.phone,
                    title: 'Phone',
                    detail: '+91 98959 89800',
                  ),

                  const Divider(color: AppColors.white24, height: 32),

                  // Email Section
                  _buildContactSection(
                    context: context,
                    icon: Icons.mail,
                    title: 'Email',
                    detail: 'mail@d4dx.co',
                  ),

                  const Divider(color: AppColors.white24, height: 32),

                  // Address Section
                  _buildContactSection(
                    context: context,
                    icon: Icons.location_on,
                    title: 'Address',
                    detail:
                        'D4DX Innovations LLP\nMavoor Road, Calicut, Kerala,\nPin 673004',
                    isMultiLine: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Additional Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.paddingSmall),
                      Text(
                        'About QSpot',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  Text(
                    'QSpot is your dedicated space for Quran videos and Islamic knowledge. We provide inspiring content from renowned speakers and scholars to help you on your spiritual journey.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String detail,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Container
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.onPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),

        const SizedBox(width: 16),

        // Text Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onPrimary,
                  height: isMultiLine ? 1.4 : 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
