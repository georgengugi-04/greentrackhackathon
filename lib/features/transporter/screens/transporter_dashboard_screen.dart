import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../shared/screens/supply_chain_dashboard.dart';

/// Transporter picks up aggregated batches and moves them onward. Receiving
/// moves a batch from [CustodyStage.withAggregator] to [CustodyStage.inTransit];
/// it then moves onward automatically once a Distributor receives it.
class TransporterDashboardScreen extends ConsumerWidget {
  const TransporterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SupplyChainDashboardScreen(
      role: UserRole.transporter,
      accent: AppColors.transporterAccent,
      emoji: '🚚',
      heading: 'Transport Hub',
      tagline: 'Move batches between farm, aggregator, distributor & market',
      incoming: ref.watch(incomingForTransporterProvider),
      held: ref.watch(transporterHeldBatchesProvider),
      incomingSectionTitle: 'Awaiting pickup',
      incomingEmptyText: 'No batches waiting for pickup from an aggregator right now.',
      receiveAction: 'Picked up from aggregator',
      receiveButtonLabel: 'Pick Up',
      newStageOnReceive: CustodyStage.inTransit,
      heldSectionTitle: 'In transit',
      heldEmptyText: 'Nothing in transit yet — pick up a batch above to get rolling.',
    );
  }
}
