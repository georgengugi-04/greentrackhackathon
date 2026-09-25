import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/messaging_service.dart';
import '../session/session_provider.dart';
import '../../data/models/models.dart';

final messagingServiceProvider = Provider<MessagingService>((_) => MessagingService());

final conversationForRequestProvider = StreamProvider.autoDispose
    .family<Conversation?, String>((ref, requestId) =>
        ref.read(messagingServiceProvider).watchConversationForRequest(requestId));

final messagesProvider = StreamProvider.autoDispose.family<List<Message>, String>(
    (ref, conversationId) =>
        ref.read(messagingServiceProvider).watchMessages(conversationId));

final myConversationsProvider = StreamProvider.autoDispose<List<Conversation>>((ref) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const Stream.empty();
  return ref.read(messagingServiceProvider).watchMyConversations(user.id);
});
