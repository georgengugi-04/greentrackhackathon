import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/models.dart';

// ── MESSAGING SERVICE ────────────────────────────────────────────────────
// One conversation per MarketplaceRequest (produce or supplier — the
// request's own targetType already tells you which). Never a standalone
// DM system: every conversation is reached by way of a request, and every
// request already carries the listing/quantity/status context needed
// alongside the chat (section 13).
class MessagingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  CollectionReference<Map<String, dynamic>> _messagesOf(String conversationId) =>
      _conversations.doc(conversationId).collection('messages');

  /// Idempotent — the first message from either side creates the
  /// conversation; after that this just returns the existing one.
  Future<Conversation> getOrCreateConversation({
    required String requestId,
    required String buyerId,
    required String sellerId,
  }) async {
    final existing =
        await _conversations.where('requestId', isEqualTo: requestId).limit(1).get();
    if (existing.docs.isNotEmpty) {
      return Conversation.fromFirestore(existing.docs.first);
    }
    final now = DateTime.now();
    final conversation = Conversation(
      id: _uuid.v4(),
      requestId: requestId,
      buyerId: buyerId,
      sellerId: sellerId,
      createdAt: now,
      updatedAt: now,
    );
    await _conversations.doc(conversation.id).set(conversation.toFirestore());
    return conversation;
  }

  Stream<Conversation?> watchConversationForRequest(String requestId) => _conversations
      .where('requestId', isEqualTo: requestId)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : Conversation.fromFirestore(s.docs.first));

  Stream<List<Message>> watchMessages(String conversationId) => _messagesOf(conversationId)
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(Message.fromFirestore).toList());

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    final message = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      message: trimmed,
      createdAt: now,
    );
    final batch = _db.batch();
    batch.set(_messagesOf(conversationId).doc(message.id), message.toFirestore());
    batch.update(_conversations.doc(conversationId), {
      'lastMessage': trimmed,
      'lastMessageAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
    await batch.commit();
  }

  /// Sorted client-side rather than via .orderBy() to avoid needing a
  /// manually-created composite index for the array-contains + orderBy
  /// combination — fine at this scale (one user's own conversation list).
  Stream<List<Conversation>> watchMyConversations(String userId) => _conversations
      .where('participantIds', arrayContains: userId)
      .snapshots()
      .map((s) {
    final list = s.docs.map(Conversation.fromFirestore).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  });
}
