// Live notifications, derived from real app state instead of a static mock
// list. Nothing here is stored as a standalone "event" — each notification
// is recomputed from current data every time a dependency changes, so it's
// always in sync with reality: harvest a batch and its reminder disappears
// on its own, no manual dismissal needed for that one.
//
// The one thing that IS session-local state is [dismissedNotificationIdsProvider]
// — swiping a notification away hides it for the rest of the session
// without needing a Firestore write, since these aren't really "messages"
// to persist, they're a live status board. If the underlying condition is
// still true next time you open the app, it'll reappear — which is
// correct: an unharvested batch that's overdue should keep surfacing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import '../session/session_provider.dart';
import '../../data/models/models.dart';

class DismissedNotificationIdsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void dismiss(String id) => state = {...state, id};
  void dismissAll(Iterable<String> ids) => state = {...state, ...ids};
}

final dismissedNotificationIdsProvider = NotifierProvider.autoDispose<
    DismissedNotificationIdsController, Set<String>>(
    DismissedNotificationIdsController.new);

/// Every real, current signal worth surfacing to *this* signed-in user,
/// based on their role. Farmers see harvest timing + PHI holds on their
/// own batches; Aggregator/Transporter/Distributor see batches waiting on
/// them specifically. Ordered most-urgent-first.
final liveNotificationsProvider = Provider.autoDispose<List<AppNotification>>((ref) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const [];

  switch (user.role) {
    case UserRole.farmer:
      return _farmerNotifications(ref);
    case UserRole.aggregator:
      return _supplyChainNotifications(
        ref.watch(incomingForAggregatorProvider),
        verb: 'receive',
        detail: 'Harvested and waiting at the farm',
      );
    case UserRole.transporter:
      return _supplyChainNotifications(
        ref.watch(incomingForTransporterProvider),
        verb: 'pick up',
        detail: 'Waiting with an aggregator',
      );
    case UserRole.distributor:
      return _supplyChainNotifications(
        ref.watch(incomingForDistributorProvider),
        verb: 'receive',
        detail: 'In transit to you',
      );
    case UserRole.chef:
    case UserRole.consumer:
      // No real, derivable per-user signal for these roles yet (no
      // custody-tracked orders/inventory for Chef, no saved-item alerts
      // for Grocery Shopper) — an honest empty feed beats a fake one.
      return const [];
  }
});

/// Notifications actually visible right now — the live list minus
/// whatever's been swiped away this session (see file header).
final visibleNotificationsProvider = Provider.autoDispose<List<AppNotification>>((ref) {
  final live = ref.watch(liveNotificationsProvider);
  final dismissed = ref.watch(dismissedNotificationIdsProvider);
  return live.where((n) => !dismissed.contains(n.id)).toList();
});

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(visibleNotificationsProvider).length;
});

List<AppNotification> _farmerNotifications(Ref ref) {
  final batches = ref.watch(farmerBatchesProvider).value ?? const [];
  final now = DateTime.now();
  final items = <_ScoredNotification>[];

  for (final b in batches) {
    // PHI hold — a batch a farmer might otherwise think is ready, but
    // legally/safely isn't yet. Always more urgent than a plain reminder.
    if (b.harvestLockedByPHI) {
      final daysLeft = b.phiDaysRemaining;
      items.add(_ScoredNotification(
        urgency: 0,
        notification: AppNotification(
          id: 'phi_${b.id}',
          title: '${b.cropName} is under a PHI hold',
          body: daysLeft <= 0
              ? 'Clearing today — safe to harvest shortly.'
              : '$daysLeft day${daysLeft == 1 ? '' : 's'} left before it\'s safe to harvest.',
          emoji: '⏳',
          type: NotificationType.phiCountdown,
          scheduledAt: now,
          cropId: b.id,
        ),
      ));
    }

    // Irrigation staleness — a batch that's actively growing but hasn't
    // had a watering logged in a while. Same "not never, just no recent
    // one" nuance whether it's never been logged at all, or it has but
    // it's gone stale.
    const activelyGrowing = {
      CropStage.planted, CropStage.sprouting, CropStage.vegetative,
      CropStage.flowering, CropStage.fruiting,
    };
    if (activelyGrowing.contains(b.stage)) {
      final lastIrrigation = b.irrigationLogs.isEmpty
          ? null
          : b.irrigationLogs.map((l) => l.timestamp).reduce((a, c) => a.isAfter(c) ? a : c);
      final sincePlanted = b.plantedDate == null
          ? null
          : now.difference(b.plantedDate!).inDays;
      final daysSinceWatered = lastIrrigation == null ? sincePlanted
          : now.difference(lastIrrigation).inDays;

      // Only nag once there's been real time to act — a batch planted
      // yesterday with nothing logged yet isn't "stale," it's just new.
      if (daysSinceWatered != null && daysSinceWatered >= 3) {
        items.add(_ScoredNotification(
          urgency: daysSinceWatered >= 6 ? 1 : 2,
          notification: AppNotification(
            id: 'irrigation_${b.id}',
            title: lastIrrigation == null
                ? '${b.cropName} has no irrigation logged yet'
                : '${b.cropName} hasn\'t been watered in $daysSinceWatered days',
            body: '${b.plotName ?? 'Your plot'} · Log a watering to keep this on track.',
            emoji: '💧',
            type: NotificationType.irrigationReminder,
            scheduledAt: now,
            cropId: b.id,
          ),
        ));
      }
    }

    // Harvest timing — urgent inside 3 days (or overdue), a lower-key
    // heads-up out to a week so a farmer isn't caught off guard.
    if (b.stage != CropStage.harvested && b.estimatedHarvestDate != null) {
      final daysLeft = b.estimatedHarvestDate!.difference(now).inDays;
      if (daysLeft <= 7) {
        final overdue = daysLeft < 0;
        items.add(_ScoredNotification(
          urgency: overdue ? 0 : (daysLeft == 0 ? 1 : (daysLeft <= 3 ? 2 : 3)),
          notification: AppNotification(
            id: 'harvest_${b.id}',
            title: overdue
                ? '${b.cropName} is overdue for harvest'
                : daysLeft == 0
                    ? '${b.cropName} is ready to harvest today'
                    : daysLeft <= 3
                        ? '${b.cropName} harvest in $daysLeft day${daysLeft == 1 ? '' : 's'}'
                        : '${b.cropName} due for harvest in about a week',
            body: '${b.plotName ?? 'Your plot'}'
                '${b.estimatedYieldKg != null ? ' · Est. ${b.estimatedYieldKg!.toStringAsFixed(1)}kg' : ''}',
            emoji: '🌾',
            type: NotificationType.harvestReminder,
            scheduledAt: now,
            cropId: b.id,
          ),
        ));
      }
    }
  }

  items.sort((a, b) => a.urgency.compareTo(b.urgency));
  return items.map((s) => s.notification).toList();
}

List<AppNotification> _supplyChainNotifications(
  List<CropBatch> incoming, {
  required String verb,
  required String detail,
}) {
  if (incoming.isEmpty) return const [];
  final now = DateTime.now();
  return incoming
      .map((b) => AppNotification(
            id: 'incoming_${b.id}',
            title: '${b.cropName} ready to $verb',
            body: detail,
            emoji: '📦',
            type: NotificationType.general,
            scheduledAt: now,
            cropId: b.id,
          ))
      .toList();
}

class _ScoredNotification {
  final int urgency; // lower = more urgent
  final AppNotification notification;
  _ScoredNotification({required this.urgency, required this.notification});
}
