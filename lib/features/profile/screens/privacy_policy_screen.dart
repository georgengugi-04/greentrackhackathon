import 'package:flutter/material.dart';
import 'legal_doc_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocScreen(
      title: 'Privacy Policy',
      lastUpdated: 'July 2026',
      intro: 'This explains what GreenTrack collects, why, and what control '
          'you have over it.',
      sections: [
        LegalSection('What We Collect',
            '• Account info: name, email, and role (Farmer, Aggregator, '
                'Transporter, Distributor, Chef, or Grocery Shopper)\n'
                '• Crop batch data: crop name, variety, farming method, planted/'
                'harvest dates, estimated yield, and notes you enter\n'
                '• Location: GPS coordinates of your plot, used to show local '
                'weather and satellite soil moisture, and pinned on the batch\'s '
                'traceability record\n'
                '• Photos: crop photos are either auto-fetched from Unsplash '
                '(a public photo library, not a photo of your actual plot) or, '
                'where you upload your own, stored so they display on your '
                'batches and harvest log\n'
                '• Custody events: for Aggregator/Transporter/Distributor '
                'accounts, a timestamped log of when your account received or '
                'released a batch'),
        LegalSection('How We Use It',
            'Batch and location data power the core traceability features — '
                'the QR trace a Diner sees when scanning a product, the '
                'irrigation/soil-moisture advice on your Farm Zone card, and the '
                'incoming/held batch lists on supply-chain dashboards. We don\'t '
                'sell your data or use it for advertising — GreenTrack doesn\'t '
                'show ads.'),
        LegalSection('Where It\'s Stored',
            'Data is stored in Firebase (Firestore for structured data, Firebase '
                'Storage for uploaded photos), operated by Google. Firestore '
                'security rules restrict who can write to a batch: only the '
                'owning Farmer can edit crop details, and other accounts '
                '(Aggregator/Transporter/Distributor) can only update custody '
                'fields when they legitimately receive or hand off a batch.'),
        LegalSection('Third-Party Services',
            'Some features call external APIs with the minimum data needed for '
                'that request: your plot\'s coordinates go to Sentinel Hub (soil '
                'moisture) and a weather provider; a photo you take goes to '
                'Kindwise (pest/disease identification) only if you use the '
                'scanner; a crop name goes to Unsplash to fetch a matching photo. '
                'These providers have their own privacy policies governing what '
                'they do with a request.'),
        LegalSection('Who Can See What',
            'Anyone who scans a batch\'s QR code can see that batch\'s public '
                'trace: crop name, origin, harvest date, and its custody journey. '
                'They cannot see your account email, other batches, or anything '
                'you haven\'t attached to that specific batch.'),
        LegalSection('Your Choices',
            '• Delete a crop batch (and its custody history) anytime from '
                'Settings → Privacy & Security → Manage Crops\n'
                '• Edit your profile photo and name from the Profile page\n'
                '• Sign out from Settings, which ends your session on this device\n'
                '• Contact us via Help & Support to ask about data we hold on '
                'your account'),
        LegalSection('Academic Project Notice',
            'GreenTrack is a university project (KCA University / JHUB Africa). '
                'Data handling described here reflects the current build and may '
                'change as the project develops toward its 2026 launch.'),
      ],
    );
  }
}
