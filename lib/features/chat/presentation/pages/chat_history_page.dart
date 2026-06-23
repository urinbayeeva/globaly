import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pill.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/conversation.dart';
import '../bloc/chat_cubit.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  late final ChatRepository _repo;
  late List<Conversation> _items;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repo = sl<ChatRepository>();
    _items = _repo.all();
  }

  void _refresh() => setState(() => _items = _repo.all());

  List<Conversation> get _filtered {
    if (_query.trim().isEmpty) return _items;
    final String q = _query.toLowerCase();
    return _items.where((Conversation c) {
      if (c.title.toLowerCase().contains(q)) return true;
      for (final m in c.messages) {
        if (m.text.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  void _openConversation(String id) {
    sl<ChatCubit>().open(id);
    if (mounted) context.go(AppRoutes.chat);
  }

  Future<void> _delete(String id) async {
    await _repo.delete(id);
    _refresh();
  }

  void _startNew() {
    sl<ChatCubit>().startNew();
    if (mounted) context.go(AppRoutes.chat);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Conversation>> groups = _groupByBucket(_filtered);
    return Scaffold(
      backgroundColor: AppColors.appBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _Header(
              count: _items.length,
              onBack: () => context.pop(),
              onNew: _startNew,
            ),
            _SearchField(
              onChanged: (String v) => setState(() => _query = v),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? _EmptyState(
                      hasAnyChats: _items.isNotEmpty,
                      onStartNew: _startNew,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: <Widget>[
                        for (final MapEntry<String, List<Conversation>> e
                            in groups.entries) ...<Widget>[
                          if (e.value.isNotEmpty) ...<Widget>[
                            _SectionLabel(
                              label: T.of(context, e.key),
                              count: e.value.length,
                            ),
                            const SizedBox(height: 8),
                            for (int i = 0; i < e.value.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ConversationCard(
                                  conversation: e.value[i],
                                  onTap: () => _openConversation(e.value[i].id),
                                  onDelete: () => _delete(e.value[i].id),
                                ),
                              ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Conversation>> _groupByBucket(List<Conversation> list) {
    final Map<String, List<Conversation>> out = <String, List<Conversation>>{
      'chat.history.today': <Conversation>[],
      'chat.history.yesterday': <Conversation>[],
      'chat.history.thisWeek': <Conversation>[],
      'chat.history.earlier': <Conversation>[],
    };
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    for (final Conversation c in list) {
      final DateTime d =
          DateTime(c.updatedAt.year, c.updatedAt.month, c.updatedAt.day);
      final int diff = today.difference(d).inDays;
      if (diff <= 0) {
        out['chat.history.today']!.add(c);
      } else if (diff == 1) {
        out['chat.history.yesterday']!.add(c);
      } else if (diff < 7) {
        out['chat.history.thisWeek']!.add(c);
      } else {
        out['chat.history.earlier']!.add(c);
      }
    }
    return out;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.onBack,
    required this.onNew,
  });
  final int count;
  final VoidCallback onBack;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandWash),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _RoundIcon(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              const Spacer(),
              _RoundIcon(
                icon: Icons.add_rounded,
                onTap: onNew,
                tint: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            T.of(context, 'chat.history.title'),
            style: AppTypography.h1.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Pill(
                label: T
                    .of(context, 'chat.history.saved')
                    .replaceAll('{0}', '$count'),
                tone: count == 0 ? PillTone.gray : PillTone.brand,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  T.of(context, 'chat.history.subtitle'),
                  style: AppTypography.bodyM.copyWith(color: AppColors.gray700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.onTap,
    this.tint = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool tint;

  @override
  Widget build(BuildContext context) {
    final Color bg = tint ? AppColors.brand : Colors.white;
    final Color fg = tint ? Colors.white : AppColors.ink;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: fg, size: 18),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.search_rounded,
              color: AppColors.gray500,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                style: AppTypography.bodyL.copyWith(color: AppColors.ink),
                cursorColor: AppColors.brand,
                decoration: InputDecoration(
                  hintText: T.of(context, 'chat.suggestionSearch'),
                  hintStyle:
                      AppTypography.bodyL.copyWith(color: AppColors.gray500),
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Row(
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppTypography.micro.copyWith(
              color: AppColors.gray500,
              fontSize: 11,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: AppTypography.micro.copyWith(
                color: AppColors.gray700,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _initial() {
    final String t = conversation.title.trim();
    if (t.isEmpty) return 'G';
    return t[0].toUpperCase();
  }

  String _lastSnippet() {
    if (conversation.messages.isEmpty) return T.t('chat.history.empty');
    final String last = conversation.messages.last.text.trim();
    if (last.length <= 90) return last;
    return '${last.substring(0, 88)}…';
  }

  String _time() {
    final DateTime now = DateTime.now();
    final DateTime when = conversation.updatedAt;
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime that = DateTime(when.year, when.month, when.day);
    final int diff = today.difference(that).inDays;
    if (diff == 0) {
      return '${_pad(when.hour)}:${_pad(when.minute)}';
    }
    if (diff == 1) return T.t('chat.history.yesterday');
    if (diff < 7) return '${diff}d';
    return '${when.year}-${_pad(when.month)}-${_pad(when.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final int messageCount = conversation.messages.length;
    return Dismissible(
      key: ValueKey<String>(conversation.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.alert,
          borderRadius: BorderRadius.circular(AppRadii.xxl),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.xxl),
              border: Border.all(color: AppColors.gray200),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0A0D1424),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Avatar(initial: _initial()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              conversation.title,
                              style: AppTypography.bodyL.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _time(),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gray500,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastSnippet(),
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.gray700,
                          height: 18 / 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          _MetaChip(
                            icon: Icons.forum_outlined,
                            text: T
                                .of(context, 'chat.history.messages')
                                .replaceAll('{0}', '$messageCount'),
                          ),
                          const SizedBox(width: 6),
                          if (messageCount > 0 &&
                              conversation.messages.last.isUser)
                            _MetaChip(
                              icon: Icons.schedule_rounded,
                              text: T.of(context, 'chat.history.waitingAi'),
                              tone: _ChipTone.amber,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});
  final String initial;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        gradient: AppColors.brandSolid,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

enum _ChipTone { gray, amber }

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
    this.tone = _ChipTone.gray,
  });
  final IconData icon;
  final String text;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (tone) {
      case _ChipTone.amber:
        bg = AppColors.warning100;
        fg = AppColors.warning700;
        break;
      case _ChipTone.gray:
        bg = AppColors.gray100;
        fg = AppColors.gray700;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.micro.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasAnyChats, required this.onStartNew});
  final bool hasAnyChats;
  final VoidCallback onStartNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: AppColors.brandSolid,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasAnyChats
                  ? T.of(context, 'chat.history.noMatches')
                  : T.of(context, 'chat.history.empty'),
              style: AppTypography.h2.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasAnyChats
                  ? T.of(context, 'chat.history.noMatchesBody')
                  : T.of(context, 'chat.history.emptyBody'),
              textAlign: TextAlign.center,
              style: AppTypography.bodyL.copyWith(
                color: AppColors.gray700,
                height: 22 / 14,
              ),
            ),
            if (!hasAnyChats) ...<Widget>[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onStartNew,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(T.of(context, 'chat.history.startFirst')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
