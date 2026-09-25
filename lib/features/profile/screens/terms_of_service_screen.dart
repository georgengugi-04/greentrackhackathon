import 'package:flutter/material.dart';
import 'legal_doc_screen.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocScreen(
      title: 'Terms of Service',
      lastUpdated: 'July 2026',
      intro: 'These terms govern your use of GreenTrack, a farm-to-table supply '
          'chain traceability app. By creating an account, you agree to the '
          'terms below.',
      sections: [
        LegalSection('1. What GreenTrack Is',
            'GreenTrack lets Farmers log crop batches, Aggregators, Transporters, '
                'and Distributors track custody as produce moves through the supply '
                'chain, and Chefs, Grocery Shoppers, and Diners trace a batch\'s '
                'origin via its QR code. It is not a marketplace, payment '
                'processor, or food-safety certification body.'),
        LegalSection('2. Accounts & Roles',
            'You choose a role (Farmer, Aggregator, Transporter, Distributor, '
                'Chef, or Grocery Shopper) when you sign up. Some actions — logging '
                'a harvest, receiving a batch, deleting a crop — are restricted to '
                'the account that owns or currently holds that batch. You\'re '
                'responsible for keeping your login credentials secure.'),
        LegalSection('3. Accuracy of Information',
            'GreenTrack displays the information users enter — crop names, '
                'weights, harvest dates, PHI (Pre-Harvest Interval) records, and '
                'custody handoffs. We don\'t independently verify these entries. '
                'Farmers and supply-chain accounts are responsible for entering '
                'accurate data, especially anything related to food safety (PHI '
                'compliance, organic certification claims).'),
        LegalSection('4. Satellite & Third-Party Data',
            'Weather, soil moisture (Sentinel-1), pest/disease identification '
                '(Kindwise), and crop photos (Unsplash) are provided by '
                'third-party services and may be approximate, delayed, or '
                'occasionally unavailable. Soil moisture readings in particular '
                'are estimates, not calibrated agronomic measurements — see the '
                'in-app note on the Farm Zone card.'),
        LegalSection('5. Content You Upload',
            'Photos, notes, and location data you add to a batch are visible to '
                'anyone who scans that batch\'s QR code, and to accounts further '
                'along the supply chain. Don\'t upload anything you don\'t want '
                'visible to downstream Aggregators, Transporters, Distributors, '
                'Chefs, or Diners.'),
        LegalSection('6. Deleting Data',
            'Farmers can delete a crop batch they own from Settings → Privacy & '
                'Security → Manage Crops. Deleting a batch removes it and its '
                'custody history permanently — this can\'t be undone, and it will '
                'break any QR codes already printed for that batch.'),
        LegalSection('7. Academic Project Disclaimer',
            'GreenTrack was built as a university project (KCA University, in '
                'partnership with JHUB Africa). It is provided "as is" for '
                'demonstration purposes, without warranty of any kind, and should '
                'not be relied on for commercial food-safety compliance without '
                'further review.'),
        LegalSection('8. Changes to These Terms',
            'We may update these terms as GreenTrack develops. Continued use '
                'after a change means you accept the updated terms.'),
        LegalSection('9. Contact',
            'Questions about these terms can be sent through Settings → Help & '
                'Support.'),
      ],
    );
  }
}
