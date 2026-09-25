import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/animated_emoji.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(visibleNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                final ids = notifications.map((n) => n.id).toSet();
                ref.read(dismissedNotificationIdsProvider.notifier).dismissAll(ids);
              },
              child: const Text('Dismiss all'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmpty(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (_, i) {
                final n = notifications[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Slidable(
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) => ref
                              .read(dismissedNotificationIdsProvider.notifier)
                              .dismiss(n.id),
                          backgroundColor: AppColors.red.withValues(alpha: 0.1),
                          foregroundColor: AppColors.red,
                          icon: Icons.close_rounded,
                          label: 'Dismiss',
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ],
                    ),
                    child: _NotificationTile(notification: n, index: i),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedEmoji('🔔', size: 56),
          const SizedBox(height: 12),
          Text('No notifications',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('You\'re all caught up!',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final int index;
  const _NotificationTile({required this.notification, required this.index});

  @override
  Widget build(BuildContext context) {
    final typeColors = {
      NotificationType.harvestReminder: AppColors.amber,
      NotificationType.phiCountdown: AppColors.blue,
      NotificationType.irrigationReminder: AppColors.blue,
      NotificationType.chefInventoryAlert: AppColors.red,
      NotificationType.buyerAvailability: AppColors.purple,
      NotificationType.scanConfirmation: AppColors.leaf,
      NotificationType.general: AppColors.leaf,
    };
    final color = typeColors[notification.type] ?? AppColors.leaf;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.cardOf(context) : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              notification.isRead ? AppColors.borderOf(context) : color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text(notification.emoji,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(notification.title,
                          style: AppTextStyles.body(13,
                              weight: FontWeight.w700,
                              color: AppColors.forest)),
                    ),
                    if (!notification.isRead)
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.amber, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notification.body,
                    style: AppTextStyles.body(11, color: AppColors.slateMid)),
                const SizedBox(height: 6),
                Text(_timeAgo(notification.scheduledAt),
                    style: AppTextStyles.body(10, color: AppColors.slateLight)),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn()
        .slideX(begin: 0.05);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
