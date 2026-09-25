import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../shared/screens/supply_chain_dashboard.dart';

/// Distributor receives in-transit batches and is the final custody-tracked
/// stop before produce reaches a Chef's kitchen or a Grocery Shopper's
/// basket — neither of which is a custody-tracked account, so the
/// Distributor's "Deliver" action is the last explicit handoff in the chain.
class DistributorDashboardScreen extends ConsumerWidget {
  const DistributorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SupplyChainDashboardScreen(
      role: UserRole.distributor,
      accent: AppColors.distributorAccent,
      emoji: '🏬',
      heading: 'Distribution Hub',
      tagline: 'Receive bulk batches and route them to chefs & retailers',
      incoming: ref.watch(incomingForDistributorProvider),
      held: ref.watch(distributorHeldBatchesProvider),
      incomingSectionTitle: 'Incoming shipments',
      incomingEmptyText: 'No batches currently in transit to you.',
      receiveAction: 'Received from transporter',
      receiveButtonLabel: 'Receive',
      newStageOnReceive: CustodyStage.withDistributor,
      heldSectionTitle: 'In my warehouse',
      heldEmptyText: 'Nothing in your warehouse yet — receive a shipment above.',
      handoffAction: 'Delivered to chef / retailer',
      handoffButtonLabel: 'Deliver',
      newStageOnHandoff: CustodyStage.delivered,
    );
  }
}
