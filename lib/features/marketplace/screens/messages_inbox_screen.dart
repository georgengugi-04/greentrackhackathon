import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/messaging_providers.dart';
import '../../../core/providers/marketplace_providers.dart';
import '../../../core/providers/supplier_providers.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/modern_components.dart';

class MessagesInboxScreen extends ConsumerWidget {
  const MessagesInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final conversationsAsync = ref.watch(myConversationsProvider);
    final me = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.messagesTitle)),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(
            child: Text(l10n.messagesErrorLoad,
                style: AppTextStyles.bodyMuted)),
        data: (conversations) {
          if (conversations.isEmpty || me == null) {
            return EmptyStateView(
              icon: Icons.chat_bubble_outline_rounded,
              title: l10n.messagesNoConversations,
              message: l10n.messagesNoConversationsMessage,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (_, i) => _ConversationTile(
              conversation: conversations[i],
              meId: me.id,
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation, required this.meId});
  final Conversation conversation;
  final String meId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(requestByIdProvider(conversation.requestId));

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.leaf.withValues(alpha: 0.15),
        child: const Icon(Icons.storefront_outlined, color: AppColors.leaf),
      ),
      title: requestAsync.when(
        loading: () => const Text('…'),
        error: (e, __) => Text(AppLocalizations.of(context)!.messagesConversationFallback),
        data: (request) => _TitleForRequest(request: request),
      ),
      subtitle: Text(
        conversation.lastMessage ?? AppLocalizations.of(context)!.messagesNoMessagesYet,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyMuted,
      ),
      trailing: conversation.lastMessageAt == null
          ? null
          : Text(DateFormat('d MMM').format(conversation.lastMessageAt!),
              style: AppTextStyles.sans(11, color: AppColors.textSecondaryOf(context))),
      onTap: () => context.push('/messages/request/${conversation.requestId}'),
    );
  }
}

class _TitleForRequest extends ConsumerWidget {
  const _TitleForRequest({required this.request});
  final MarketplaceRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (request == null) return Text(l10n.messagesConversationFallback);
    final isSupplier = request!.targetType == MarketplaceRequestTarget.supplier;
    final titleAsync = isSupplier
        ? ref.watch(supplierListingByIdProvider(request!.listingId))
        : ref.watch(listingByIdProvider(request!.listingId));

    String title = l10n.messagesConversationFallback;
    if (titleAsync.hasValue) {
      final v = titleAsync.value;
      if (v is SupplierListing) title = v.name;
      if (v is MarketplaceListing) title = v.cropName;
    }
    return Text(title, style: AppTextStyles.sans(14, weight: FontWeight.w700));
  }
}
