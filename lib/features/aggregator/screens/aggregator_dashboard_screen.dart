import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../shared/screens/supply_chain_dashboard.dart';

/// Aggregator receives harvested batches straight from farmers and combines
/// them into trade-ready lots. Once received, a batch moves from
/// [CustodyStage.atFarm] to [CustodyStage.withAggregator] — from there it
/// moves onward automatically the moment a Transporter receives it, so
/// this screen has no separate hand-off step of its own.
class AggregatorDashboardScreen extends ConsumerWidget {
  const AggregatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SupplyChainDashboardScreen(
      role: UserRole.aggregator,
      accent: AppColors.aggregatorAccent,
      emoji: '📦',
      heading: 'Aggregation Hub',
      tagline: 'Combine farmer harvests into trade-ready batches',
      incoming: ref.watch(incomingForAggregatorProvider),
      held: ref.watch(aggregatorHeldBatchesProvider),
      incomingSectionTitle: 'Ready for pickup',
      incomingEmptyText: 'No harvested batches waiting at the farm right now.',
      receiveAction: 'Received from farm',
      receiveButtonLabel: 'Receive',
      newStageOnReceive: CustodyStage.withAggregator,
      heldSectionTitle: 'In my custody',
      heldEmptyText: 'Nothing in your custody yet — receive a batch above to get started.',
    );
  }
}
