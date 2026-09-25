import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/marketplace_providers.dart';
import '../../../core/providers/supplier_providers.dart';
import '../../../core/providers/messaging_providers.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/models/models.dart';

/// Chat tied to one MarketplaceRequest — works for both produce and
/// supplier requests, since they share the same request/status model
/// (section 13: communication always anchored to a request, never a
/// free-standing DM system).
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _conversationId;
  String? _errorText;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureConversation(MarketplaceRequest request) async {
    if (_conversationId != null) return;
    try {
      final conversation =
          await ref.read(messagingServiceProvider).getOrCreateConversation(
                requestId: request.id,
                buyerId: request.buyerId,
                sellerId: request.sellerId,
              );
      if (mounted) setState(() => _conversationId = conversation.id);
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = AppLocalizations.of(context)!.conversationErrorOpen);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requestAsync = ref.watch(requestByIdProvider(widget.requestId));
    final me = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.conversationTitle)),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(
            child: Text(l10n.conversationErrorLoad,
                style: AppTextStyles.bodyMuted)),
        data: (request) {
          if (request == null || me == null) {
            return Center(
                child: Text(l10n.conversationRequestUnavailable,
                    style: AppTextStyles.bodyMuted));
          }
          // Kick off (idempotent) conversation creation once, without
          // doing Firestore writes inside build().
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _ensureConversation(request));

          return Column(children: [
            _RequestContextHeader(request: request),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: _conversationId == null
                  ? const Center(child: CircularProgressIndicator())
                  : _MessageList(
                      conversationId: _conversationId!,
                      meId: me.id,
                      scrollCtrl: _scrollCtrl,
                    ),
            ),
            _Composer(
              controller: _textCtrl,
              onSend: _conversationId == null
                  ? null
                  : () async {
                      final text = _textCtrl.text;
                      _textCtrl.clear();
                      await ref.read(messagingServiceProvider).sendMessage(
                            conversationId: _conversationId!,
                            senderId: me.id,
                            text: text,
                          );
                    },
            ),
          ]);
        },
      ),
    );
  }
}

class _RequestContextHeader extends ConsumerWidget {
  const _RequestContextHeader({required this.request});
  final MarketplaceRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSupplier = request.targetType == MarketplaceRequestTarget.supplier;
    final titleAsync = isSupplier
        ? ref.watch(supplierListingByIdProvider(request.listingId))
        : ref.watch(listingByIdProvider(request.listingId));

    String title = AppLocalizations.of(context)!.conversationRequestFallback;
    if (titleAsync.hasValue) {
      final v = titleAsync.value;
      if (v is SupplierListing) title = v.name;
      if (v is MarketplaceListing) title = v.cropName;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        border: Border(bottom: BorderSide(color: AppColors.borderOf(context))),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.sans(14, weight: FontWeight.w700)),
              Text('${request.quantity.toStringAsFixed(0)} ${request.unit}',
                  style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.premiumWarning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(request.status.label,
              style: AppTextStyles.sans(11,
                  weight: FontWeight.w700, color: AppColors.premiumWarning)),
        ),
      ]),
    );
  }
}

class _MessageList extends ConsumerWidget {
  const _MessageList({required this.conversationId, required this.meId, required this.scrollCtrl});
  final String conversationId;
  final String meId;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider(conversationId));

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(
          child: Text(AppLocalizations.of(context)!.conversationErrorLoadMessages,
              style: AppTextStyles.bodyMuted)),
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
              child: Text(AppLocalizations.of(context)!.conversationSayHello,
                  style: AppTextStyles.bodyMuted, textAlign: TextAlign.center));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollCtrl.hasClients) {
            scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
          }
        });
        return ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            final m = messages[i];
            final mine = m.senderId == meId;
            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: mine ? AppColors.leaf : AppColors.cardOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: mine ? null : Border.all(color: AppColors.borderOf(context)),
                ),
                child: Text(m.message,
                    style: AppTextStyles.sans(14,
                        color: mine ? Colors.white : AppColors.textPrimaryOf(context))),
              ),
            );
          },
        );
      },
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.conversationHint,
                filled: true,
                fillColor: AppColors.cardOf(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => onSend?.call(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(backgroundColor: AppColors.leaf),
          ),
        ]),
      ),
    );
  }
}
