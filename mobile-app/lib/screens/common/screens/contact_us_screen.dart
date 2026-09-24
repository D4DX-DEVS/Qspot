import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Contact Us',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
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
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We'd love to hear from you",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.secondaryGray),
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

                  const Divider(color: Colors.white24, height: 32),

                  // Email Section
                  _buildContactSection(
                    context: context,
                    icon: Icons.mail,
                    title: 'Email',
                    detail: 'mail@d4dx.co',
                  ),

                  const Divider(color: Colors.white24, height: 32),

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
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.gradientEnd,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.paddingSmall),
                      Text(
                        'About QSpot',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  Text(
                    'QSpot is your dedicated space for Quran videos and Islamic knowledge. We provide inspiring content from renowned speakers and scholars to help you on your spiritual journey.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
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
            color: AppTheme.primaryWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.gradientStart, size: 24),
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
                  color: AppTheme.primaryWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryWhite,
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
