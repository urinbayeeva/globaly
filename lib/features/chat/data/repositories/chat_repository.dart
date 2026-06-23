import 'dart:convert';

import '../../../../core/storage/prefs.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/conversation.dart';

class ChatRepository {
  ChatRepository(this._prefs);
  final Prefs _prefs;

  static const String _kConversations = 'chat_conversations';
  static const String _kActiveId = 'chat_active_id';

  List<Conversation> all() {
    final String? raw = _prefs.getString(_kConversations);
    if (raw == null || raw.isEmpty) return <Conversation>[];
    try {
      final List<dynamic> arr = jsonDecode(raw) as List<dynamic>;
      final List<Conversation> out = arr
          .whereType<Map<String, dynamic>>()
          .map(Conversation.fromJson)
          .whereType<Conversation>()
          .toList()
        ..sort(
          (Conversation a, Conversation b) =>
              b.updatedAt.compareTo(a.updatedAt),
        );
      return out;
    } catch (e) {
      appLogger.w('💬 chat repo: failed to parse conversations: $e');
      return <Conversation>[];
    }
  }

  Conversation? byId(String id) {
    for (final Conversation c in all()) {
      if (c.id == id) return c;
    }
    return null;
  }

  String? activeId() => _prefs.getString(_kActiveId);

  Future<void> setActiveId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kActiveId);
    } else {
      await _prefs.setString(_kActiveId, id);
    }
  }

  Future<void> upsert(Conversation conversation) async {
    final List<Conversation> list = all();
    final int idx =
        list.indexWhere((Conversation c) => c.id == conversation.id);
    if (idx >= 0) {
      list[idx] = conversation;
    } else {
      list.add(conversation);
    }
    await _persist(list);
  }

  Future<void> delete(String id) async {
    final List<Conversation> list = all()
      ..removeWhere((Conversation c) => c.id == id);
    await _persist(list);
    if (activeId() == id) await setActiveId(null);
  }

  Future<void> _persist(List<Conversation> list) async {
    final List<Map<String, dynamic>> raw =
        list.map((Conversation c) => c.toJson()).toList();
    await _prefs.setString(_kConversations, jsonEncode(raw));
  }
}
