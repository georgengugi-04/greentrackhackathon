import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/marketplace_providers.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/models/models.dart';

/// Structured request form (spec section 11) — quantity, unit, intended
/// use, preferred date, fulfilment preference, optional message. Consumers
/// and business buyers use the same form; the "intended use" field is what
/// lets a business buyer signal scale without forcing every consumer
/// through a heavier workflow (section 10).
class RequestProduceScreen extends ConsumerStatefulWidget {
  const RequestProduceScreen({super.key, required this.listingId});
  final String listingId;

  @override
  ConsumerState<RequestProduceScreen> createState() =>
      _RequestProduceScreenState();
}

class _RequestProduceScreenState extends ConsumerState<RequestProduceScreen> {
  final _qtyCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  IntendedUse _intendedUse = IntendedUse.personal;
  FulfilmentPreference _fulfilment = FulfilmentPreference.discuss;
  DateTime? _preferredDate;
  bool _sending = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listingAsync = ref.watch(listingByIdProvider(widget.listingId));

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.requestTitle)),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(
            child: Text(l10n.listingErrorLoad, style: AppTextStyles.bodyMuted)),
        data: (listing) {
          if (listing == null) {
            return Center(
                child: Text(l10n.listingNoLongerAvailable,
                    style: AppTextStyles.bodyMuted));
          }
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(listing.cropName,
                    style: AppTextStyles.poppins(20, weight: FontWeight.w700)),
                Text(
                    l10n.marketplaceAvailableQuantity(
                        listing.availableQuantity.toStringAsFixed(0), listing.unit),
                    style: AppTextStyles.bodyMuted),
                const SizedBox(height: 20),
                Text(l10n.requestQuantityLabel(listing.unit),
                    style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      hintText: l10n.requestQuantityHint, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 18),
                Text(l10n.requestIntendedUse,
                    style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<IntendedUse>(
                  initialValue: _intendedUse,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: IntendedUse.values
                      .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _intendedUse = v!),
                ),
                const SizedBox(height: 18),
                Text(l10n.requestFulfilmentPreference,
                    style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<FulfilmentPreference>(
                  initialValue: _fulfilment,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: FulfilmentPreference.values
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _fulfilment = v!),
                ),
                const SizedBox(height: 18),
                Text(l10n.requestPreferredDate,
                    style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 2)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 180)),
                    );
                    if (picked != null) setState(() => _preferredDate = picked);
                  },
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      alignment: Alignment.centerLeft),
                  child: Text(_preferredDate == null
                      ? l10n.requestChooseDate
                      : DateFormat('d MMMM yyyy').format(_preferredDate!)),
                ),
                const SizedBox(height: 18),
                Text(l10n.requestMessage,
                    style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                      hintText: l10n.requestMessageHint, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _sending ? null : () => _send(listing),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: AppColors.premiumEmerald),
                  child: _sending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.requestSend),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _send(MarketplaceListing listing) async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(sessionProvider);
    if (user == null) return;
    final qty = double.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.requestErrorInvalidQuantity)));
      return;
    }
    if (qty > listing.availableQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.requestErrorQuantityTooHigh)));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(marketplaceServiceProvider).createRequest(
            listing: listing,
            buyerId: user.id,
            buyerName: user.name,
            quantity: qty,
            intendedUse: _intendedUse,
            fulfilmentPreference: _fulfilment,
            preferredDate: _preferredDate,
            message: _messageCtrl.text.trim().isEmpty
                ? null
                : _messageCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.requestSentToFarmer)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.requestErrorGeneric(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
