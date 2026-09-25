// Shared dashboard for the three "middle of the chain" roles GreenTrack
// added alongside Farmer/Chef/Grocery Shopper/Diner: Aggregator, Transporter,
// and Distributor. All three follow the same shape — a list of batches one
// step behind them in the chain that they can receive, and a list of
// batches currently in their own custody — so this one widget is
// configured per-role rather than copy-pasted three times.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../widgets/animated_emoji.dart';
import '../widgets/user_avatar.dart';
import '../widgets/premium_widgets.dart';

class SupplyChainDashboardScreen extends ConsumerWidget {
  final UserRole role;
  final Color accent;
  final String emoji;
  final String heading; // e.g. "Aggregation Hub"
  final String tagline; // e.g. "Combine farmer harvests into trade batches"

  final List<CropBatch> incoming;
  final List<CropBatch> held;

  final String incomingSectionTitle; // e.g. "Ready for pickup"
  final String incomingEmptyText;
  final String receiveAction; // logged text, e.g. "Received from farm"
  final String receiveButtonLabel; // e.g. "Receive"
  final CustodyStage newStageOnReceive;

  final String heldSectionTitle; // e.g. "In my custody"
  final String heldEmptyText;

  // Only the Distributor currently needs a final hand-off step (Chef/
  // Grocery Shopper aren't custody-tracked accounts) — Aggregator and
  // Transporter batches move forward automatically the moment the next
  // role in the chain receives them.
  final String? handoffAction;
  final String? handoffButtonLabel;
  final CustodyStage? newStageOnHandoff;

  const SupplyChainDashboardScreen({
    super.key,
    required this.role,
    required this.accent,
    required this.emoji,
    required this.heading,
    required this.tagline,
    required this.incoming,
    required this.held,
    required this.incomingSectionTitle,
    required this.incomingEmptyText,
    required this.receiveAction,
    required this.receiveButtonLabel,
    required this.newStageOnReceive,
    required this.heldSectionTitle,
    required this.heldEmptyText,
    this.handoffAction,
    this.handoffButtonLabel,
    this.newStageOnHandoff,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final orgName = user?.organizationName ?? user?.vehicleInfo ?? user?.name ?? role.label;

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, Color.lerp(accent, Colors.black, 0.35)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(role.label.toUpperCase(),
                    style: AppTextStyles.poppins(11.5, weight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.75)).copyWith(letterSpacing: 0.8))),
                InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => context.push('/notifications'),
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                    ),
                    if (incoming.isNotEmpty)
                      Positioned(top: -3, right: -3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          decoration: BoxDecoration(
                              color: AppColors.premiumWarning, shape: BoxShape.circle,
                              border: Border.all(color: accent, width: 1.5)),
                          alignment: Alignment.center,
                          child: Text(incoming.length > 9 ? '9+' : '${incoming.length}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 10,
                                  fontWeight: FontWeight.w800, height: 1)),
                        )),
                  ]),
                ),
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => context.push('/settings'),
                  child: RingAvatar(
                    photoUrl: user?.photoUrl,
                    fallbackText: orgName,
                    size: 44,
                    completion: 1.0,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text(orgName,
                    style: AppTextStyles.poppins(22, color: Colors.white, weight: FontWeight.w700)),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: AnimatedEmoji(emoji, size: 20),
                ),
              ]),
              const SizedBox(height: 4),
              Text(tagline,
                  style: AppTextStyles.poppins(12.5, color: Colors.white.withValues(alpha: 0.75))),
            ]),
          ),
        )),
        SliverToBoxAdapter(child: Transform.translate(
          offset: const Offset(0, -18),
          child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(children: [
            ModernStatCard(
              icon: Icons.move_to_inbox_rounded,
              color: accent,
              label: incomingSectionTitle,
              value: incoming.length,
              caption: 'Waiting',
            ),
            const SizedBox(width: 10),
            ModernStatCard(
              icon: Icons.inventory_2_rounded,
              color: accent,
              label: heldSectionTitle,
              value: held.length,
              caption: 'In custody',
            ),
          ]),
        ))),
        SliverToBoxAdapter(child: _SectionHeader(incomingSectionTitle)),
        if (incoming.isEmpty)
          SliverToBoxAdapter(child: _EmptyState(incomingEmptyText))
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, i) => _BatchCard(
              batch: incoming[i],
              accent: accent,
              buttonLabel: receiveButtonLabel,
              onAction: () => _confirmAndAct(
                context: context,
                ref: ref,
                batch: incoming[i],
                title: receiveButtonLabel,
                action: receiveAction,
                isReceive: true,
                newStage: newStageOnReceive,
              ),
            ),
            childCount: incoming.length,
          )),
        SliverToBoxAdapter(child: _SectionHeader(heldSectionTitle)),
        if (held.isEmpty)
          SliverToBoxAdapter(child: _EmptyState(heldEmptyText))
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, i) => _BatchCard(
              batch: held[i],
              accent: accent,
              buttonLabel: handoffButtonLabel,
              secondary: true,
              onAction: handoffButtonLabel == null
                  ? null
                  : () => _confirmAndAct(
                        context: context,
                        ref: ref,
                        batch: held[i],
                        title: handoffButtonLabel!,
                        action: handoffAction!,
                        isReceive: false,
                        newStage: newStageOnHandoff!,
                      ),
            ),
            childCount: held.length,
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ]),
    );
  }

  Future<void> _confirmAndAct({
    required BuildContext context,
    required WidgetRef ref,
    required CropBatch batch,
    required String title,
    required String action,
    required bool isReceive,
    required CustodyStage newStage,
  }) async {
    final user = ref.read(sessionProvider);
    if (user == null) return;
    final notesCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardOf(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$title — ${batch.cropName}',
              style: AppTextStyles.poppins(19, weight: FontWeight.w700, color: AppColors.textPrimaryOf(ctx))),
          const SizedBox(height: 6),
          Text('Batch #${batch.id.substring(0, batch.id.length >= 6 ? 6 : batch.id.length).toUpperCase()}',
              style: AppTextStyles.sans(12.5, color: AppColors.textSecondaryOf(ctx))),
          const SizedBox(height: 16),
          TextField(
            controller: notesCtrl,
            maxLines: 2,
            style: TextStyle(color: AppColors.textPrimaryOf(ctx)),
            decoration: InputDecoration(
              hintText: 'Notes — condition, location, vehicle... (optional)',
              filled: true,
              fillColor: AppColors.surfaceOf(ctx),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirm $title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final service = ref.read(batchServiceProvider);
      if (isReceive) {
        await service.receiveBatch(
          batchId: batch.id,
          actor: user,
          newStage: newStage,
          action: action,
          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        );
      } else {
        await service.handOffBatch(
          batchId: batch.id,
          actor: user,
          newStage: newStage,
          action: action,
          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title logged for ${batch.cropName}'), backgroundColor: accent),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not log this handoff: $e')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
    child: Text(title.toUpperCase(),
        style: AppTextStyles.poppins(12, weight: FontWeight.w700,
            color: AppColors.textSecondaryOf(context)).copyWith(letterSpacing: 0.8)),
  );
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppShadows.subtle,
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: AppTextStyles.poppins(13, color: AppColors.textSecondaryOf(context))),
    ),
  );
}

class _BatchCard extends StatelessWidget {
  final CropBatch batch;
  final Color accent;
  final String? buttonLabel;
  final VoidCallback? onAction;
  final bool secondary;
  const _BatchCard({
    required this.batch,
    required this.accent,
    required this.buttonLabel,
    required this.onAction,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppShadows.card,
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.eco_rounded, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(batch.cropName, style: AppTextStyles.poppins(15.5, weight: FontWeight.w700,
              color: AppColors.textPrimaryOf(context))),
          const SizedBox(height: 2),
          Text(
            batch.verifiedWeightKg != null
                ? '${batch.verifiedWeightKg!.toStringAsFixed(1)} kg · ${batch.plotName ?? batch.farmerId}'
                : (batch.plotName ?? 'Farm plot'),
            style: AppTextStyles.poppins(12, color: AppColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 2),
          Text(batch.custodyStage.label,
              style: AppTextStyles.poppins(11, color: accent, weight: FontWeight.w700)),
        ])),
        if (buttonLabel != null && onAction != null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: secondary ? accent.withValues(alpha: 0.15) : accent,
              foregroundColor: secondary ? accent : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onAction,
            child: Text(buttonLabel!, style: AppTextStyles.poppins(12.5, weight: FontWeight.w700,
                color: secondary ? accent : Colors.white)),
          ),
      ]),
    );
  }
}
