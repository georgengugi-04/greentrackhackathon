import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LegalSection {
  final String heading;
  final String body;
  const LegalSection(this.heading, this.body);
}

/// Renders a title + intro + a list of heading/body sections. Used for both
/// Terms of Service and Privacy Policy so the two documents look and read
/// consistently rather than being two one-off screens.
class LegalDocScreen extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final String intro;
  final List<LegalSection> sections;
  const LegalDocScreen({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text('Last updated: $lastUpdated',
              style: AppTextStyles.body(12, color: AppColors.textSecondaryOf(context))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.amberPale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.amber),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'GreenTrack is a university project (KCA University / JHUB Africa). '
                'This document is a template for demo purposes — it is not '
                'reviewed legal counsel and should be replaced before any '
                'real-world launch.',
                style: AppTextStyles.body(11.5, color: AppColors.textPrimaryOf(context)),
              )),
            ]),
          ),
          const SizedBox(height: 20),
          Text(intro, style: AppTextStyles.body(14, color: AppColors.textPrimaryOf(context), height: 1.5)),
          const SizedBox(height: 24),
          ...sections.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.heading,
                  style: AppTextStyles.body(15.5, weight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context))),
              const SizedBox(height: 6),
              Text(s.body,
                  style: AppTextStyles.body(13.5,
                      color: AppColors.textSecondaryOf(context), height: 1.55)),
            ]),
          )),
        ],
      ),
    );
  }
}
