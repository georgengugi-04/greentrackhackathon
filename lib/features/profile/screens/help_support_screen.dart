import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class _Faq {
  final String q, a;
  const _Faq(this.q, this.a);
}

const _faqs = [
  _Faq('How do I log a new crop batch?',
      'From the Farmer home screen, tap the + button. Fill in the plot name, '
          'crop name, farming method, and expected harvest date — a photo is '
          'fetched automatically from Unsplash once you type the crop name.'),
  _Faq('Why isn\'t my crop showing in the Harvest tab?',
      'The Harvest tab has two sections: "Upcoming Harvests" for batches still '
          'growing, and "Harvest Log" for ones you\'ve already harvested. A '
          'freshly planted crop appears under Upcoming, not the log.'),
  _Faq('What is a PHI hold?',
      'PHI (Pre-Harvest Interval) is the required waiting period after a pest/'
          'disease treatment before it\'s safe to harvest. If a batch has an '
          'active PHI hold, you\'ll see a countdown on your dashboard and '
          'Notifications — GreenTrack won\'t mark it as ready until it clears.'),
  _Faq('How does a batch move through the supply chain?',
      'Farmer → Aggregator → Transporter → Distributor → Chef/Grocery Shopper. '
          'Each role taps "Receive" to take custody — the batch then '
          'automatically appears in the next role\'s incoming list. Every '
          'handoff is logged and shown on the batch\'s QR trace.'),
  _Faq('Who can see my batch\'s data?',
      'Anyone who scans the QR code sees that batch\'s public trace (crop, '
          'origin, harvest date, custody history). Your account email and other '
          'batches stay private.'),
  _Faq('Can I delete a crop I planted by mistake?',
      'Yes — go to Settings → Privacy & Security → Manage Crops. This is '
          'permanent and also removes the batch\'s custody history.'),
  _Faq('The soil moisture tile isn\'t showing on my Farm Zone card.',
      'That feature needs Sentinel Hub satellite credentials configured by '
          'whoever built your copy of the app, and Sentinel-1 only revisits a '
          'given location every 6–12 days — it may just not have a recent pass.'),
];

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('FREQUENTLY ASKED QUESTIONS',
              style: AppTextStyles.poppins(11.5, weight: FontWeight.w700,
                  color: AppColors.textSecondaryOf(context)).copyWith(letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
              boxShadow: AppShadows.card,
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: List.generate(_faqs.length * 2 - 1, (i) {
                if (i.isOdd) {
                  return Divider(height: 1, color: AppColors.borderOf(context));
                }
                final faq = _faqs[i ~/ 2];
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(faq.q,
                        style: AppTextStyles.poppins(13.5, weight: FontWeight.w600,
                            color: AppColors.textPrimaryOf(context))),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faq.a,
                          style: AppTextStyles.body(12.5,
                              color: AppColors.textSecondaryOf(context), height: 1.5)),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Text('CONTACT US',
              style: AppTextStyles.poppins(11.5, weight: FontWeight.w700,
                  color: AppColors.textSecondaryOf(context)).copyWith(letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
              boxShadow: AppShadows.card,
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: AppColors.leaf.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.email_outlined, size: 18, color: AppColors.leaf),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('support@greentrack.co.ke',
                    style: AppTextStyles.poppins(13.5, weight: FontWeight.w600,
                        color: AppColors.textPrimaryOf(context))),
                Text('Tap to copy',
                    style: AppTextStyles.body(11, color: AppColors.textSecondaryOf(context))),
              ])),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: AppColors.textSecondaryOf(context),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'support@greentrack.co.ke'));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email address copied')));
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
