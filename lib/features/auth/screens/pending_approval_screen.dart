import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/animated_emoji.dart';

/// Watches the user's own request live — an admin approving from
/// /admin/approvals flips this screen straight to the dashboard without
/// the user needing to do anything, since [myRoleRequestProvider] and the
/// router's redirect both react to the same underlying Firestore write.
class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final requestAsync = ref.watch(myRoleRequestProvider);

    return Scaffold(
      backgroundColor: AppColors.night,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(child: requestAsync.when(
          loading: () => const CircularProgressIndicator(color: Colors.white),
          error: (e, _) => _StatusBody(
            emoji: '⚠️',
            title: 'Something went wrong',
            body: 'Could not check your request status. Pull to refresh or try again shortly.',
            accent: AppColors.red,
          ),
          data: (request) {
            if (request == null || request.status == VerificationStatus.pending) {
              return _StatusBody(
                emoji: '⏳',
                title: 'Pending Review',
                body: '${user?.role.label ?? 'Your'} access request for '
                    '"${request?.organizationDetail ?? ''}" is waiting on an '
                    'admin to review it. This screen updates automatically the '
                    'moment a decision is made — no need to keep checking.',
                accent: AppColors.amber,
              );
            }
            if (request.status == VerificationStatus.rejected) {
              return _StatusBody(
                emoji: '❌',
                title: 'Not Approved',
                body: 'Your request wasn\'t approved this time. If you believe '
                    'this is a mistake, reach out through Help & Support, or try '
                    'again with an invite code if you have one.',
                accent: AppColors.red,
                actionLabel: 'Sign Out',
                onAction: () async {
                  await ref.read(sessionProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
              );
            }
            // approved — router redirect handles navigation, but show a
            // brief confirming state in case there's a beat before it fires.
            return _StatusBody(
              emoji: '✅',
              title: 'Approved!',
              body: 'Taking you to your dashboard...',
              accent: AppColors.leaf,
            );
          },
        )),
      )),
    );
  }
}

class _StatusBody extends StatelessWidget {
  final String emoji, title, body;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _StatusBody({
    required this.emoji,
    required this.title,
    required this.body,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedEmoji(emoji, size: 56),
      const SizedBox(height: 18),
      Text(title, style: AppTextStyles.poppins(24, color: Colors.white, weight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text(body, textAlign: TextAlign.center,
          style: AppTextStyles.sans(13.5, color: Colors.white70, height: 1.5)),
      if (actionLabel != null) ...[
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: onAction,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: accent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(actionLabel!, style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
        )),
      ],
    ]);
  }
}
