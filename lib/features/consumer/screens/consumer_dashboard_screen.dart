import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/scan_history_provider.dart';
import '../../shared/widgets/premium_widgets.dart';

class ConsumerDashboardScreen extends ConsumerWidget {
  const ConsumerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(sessionProvider);
    final history = ref.watch(scanHistoryProvider);
    final firstName = (user?.name ?? l10n.consumerGreetingFallbackName).split(' ').first;

    // Real, derived stats — nothing fabricated. All three come straight
    // from the user's actual scan history.
    final organicCount = history.where((e) => e.badge).length;
    final mealsCount = history.where((e) => e.kind == ScanKind.meal).length;

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.premiumBackground),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ShopperHeader(
                  name: firstName,
                  onSettingsTap: () {
                    ref.read(sessionProvider.notifier).signOut();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, 0),
                    child: Row(children: [
                      ModernStatCard(
                        icon: Icons.qr_code_scanner_rounded,
                        color: AppColors.consumerAccent,
                        label: l10n.statScans,
                        value: history.length,
                        caption: l10n.statTotalTraced,
                      ),
                      const SizedBox(width: 12),
                      ModernStatCard(
                        icon: Icons.eco_rounded,
                        color: AppColors.premiumEmerald,
                        label: l10n.statOrganic,
                        value: organicCount,
                        caption: l10n.statVerified,
                      ),
                      const SizedBox(width: 12),
                      ModernStatCard(
                        icon: Icons.restaurant_rounded,
                        color: AppColors.premiumWarning,
                        label: l10n.statMeals,
                        value: mealsCount,
                        caption: l10n.statTraced,
                      ),
                    ]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                  child: _ScanHeroCard(onTap: () => context.push('/scan')),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: QuickActionCard(
                    icon: Icons.storefront_rounded,
                    color: AppColors.leaf,
                    title: l10n.dashboardMarketplaceTitle,
                    subtitle: l10n.dashboardMarketplaceSubtitle,
                    description: l10n.dashboardMarketplaceDescription,
                    onTap: () => context.push('/marketplace'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
                  child: SectionHeader(
                    title: l10n.consumerRecentScans,
                    action: history.isEmpty ? null : '${history.length}',
                  ),
                ),
              ),
              if (history.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                    child: _EmptyScansState(onTap: () => context.push('/scan')),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverList.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final entry = history[i];
                      return _ScanHistoryCard(
                        entry: entry,
                        onTap: () => context.push(entry.kind == ScanKind.meal
                            ? '/consumer/meal/${entry.id}'
                            : '/consumer/scan/${entry.id}'),
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient header — same visual family as PremiumProfileHeader, in the
// consumer/shopper blue accent instead of the farmer green.
// ---------------------------------------------------------------------------

class _ShopperHeader extends StatelessWidget {
  final String name;
  final VoidCallback onSettingsTap;
  const _ShopperHeader({required this.name, required this.onSettingsTap});

  String _greeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.consumerGoodMorning;
    if (hour < 17) return l10n.consumerGoodAfternoon;
    return l10n.consumerGoodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B3F8F), Color(0xFF2D6CDF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_greeting(context)},',
                    style: AppTextStyles.poppins(14,
                        color: Colors.white.withValues(alpha: 0.78),
                        weight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(name,
                    style: AppTextStyles.poppins(24,
                        color: Colors.white, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(l10n.consumerPlateTagline,
                    style: AppTextStyles.poppins(12.5,
                        color: Colors.white.withValues(alpha: 0.72),
                        weight: FontWeight.w500)),
              ],
            ),
          ),
          _RoundIconButton(icon: Icons.logout_rounded, onTap: onSettingsTap),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero "Scan a QR code" card
// ---------------------------------------------------------------------------

class _ScanHeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanHeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 168,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl - 6),
          gradient: const LinearGradient(
            colors: [Color(0xFF2D6CDF), Color(0xFF1B3F8F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.consumerAccent.withValues(alpha: 0.32),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Soft glow orb for depth, same trick used on the dark
            // login/scanner screens elsewhere in the app.
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.consumerScanQrCode,
                      style: AppTextStyles.poppins(17,
                          color: Colors.white, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(l10n.consumerScanQrSubtitle,
                      style: AppTextStyles.poppins(12,
                          color: Colors.white.withValues(alpha: 0.75))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — shown until the user has actually scanned something
// ---------------------------------------------------------------------------

class _EmptyScansState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyScansState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(AppRadius.xl - 6),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.consumerAccent.withValues(alpha: 0.10),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.consumerAccent, size: 26),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.consumerNoScansYet,
              style: AppTextStyles.poppins(17,
                  weight: FontWeight.w700, color: AppColors.textPrimaryOf(context))),
          const SizedBox(height: 4),
          Text(
            l10n.consumerNoScansMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.poppins(12.5,
                color: AppColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: Text(l10n.consumerScanFirstProduct),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A real, previously-scanned product
// ---------------------------------------------------------------------------

class _ScanHistoryCard extends StatelessWidget {
  final ScanHistoryEntry entry;
  final VoidCallback onTap;
  const _ScanHistoryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardOf(context),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderOf(context)),
            boxShadow: AppShadows.subtle,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (entry.badge
                          ? AppColors.leaf
                          : AppColors.consumerAccent)
                      .withValues(alpha: 0.12),
                ),
                child: Icon(
                  entry.kind == ScanKind.meal
                      ? Icons.restaurant_rounded
                      : entry.badge
                          ? Icons.eco_rounded
                          : Icons.inventory_2_rounded,
                  color: entry.badge ? AppColors.leaf : AppColors.consumerAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(entry.title,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.poppins(15,
                                  weight: FontWeight.w700,
                                  color: AppColors.textPrimaryOf(context))),
                        ),
                        if (entry.badge) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.leaf.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(AppLocalizations.of(context)!.consumerOrganicBadge,
                                style: AppTextStyles.poppins(9.5,
                                    color: AppColors.leaf,
                                    weight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(entry.subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.poppins(12,
                            color: AppColors.textSecondaryOf(context))),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(_relativeTime(context, entry.scannedAt),
                  style: AppTextStyles.poppins(11,
                      color: AppColors.textSecondaryOf(context))),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textSecondaryOf(context)),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeTime(BuildContext context, DateTime t) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return '${t.day}/${t.month}/${t.year}';
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
