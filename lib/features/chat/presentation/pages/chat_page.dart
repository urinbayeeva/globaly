import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/app_topbar.dart';
import '../../../../core/widgets/pill.dart';
import '../bloc/chat_cubit.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/suggested_chips.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> prompts = <String>[
      T.of(context, 'chat.prompts.roadmap'),
      T.of(context, 'chat.prompts.docs'),
      T.of(context, 'chat.prompts.cost'),
    ];

    return BlocProvider<ChatCubit>.value(
      value: sl<ChatCubit>(),
      child: Container(
        color: AppColors.appBg,
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<ChatCubit, ChatState>(
            builder: (BuildContext c, ChatState s) {
              final ChatCubit cubit = c.read<ChatCubit>();
              final bool showSuggestions = !s.hasUserMessage && !s.typing;
              return Column(
                children: <Widget>[
                  AppTopbar(
                    title: T.of(context, 'chat.title'),
                    subtitle: T.of(context, 'chat.subtitle'),
                    trailing: _HeaderActions(
                      onHistory: () => c.push(AppRoutes.chatHistory),
                      onNew: cubit.startNew,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      itemCount: s.messages.length + (s.typing ? 1 : 0),
                      itemBuilder: (BuildContext ctx, int i) {
                        if (s.typing && i == s.messages.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  T.of(context, 'chat.typing'),
                                  style: AppTypography.caption
                                      .copyWith(color: AppColors.gray500),
                                ),
                                const SizedBox(height: 8),
                                AppShimmer(
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 240),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(18),
                                        topRight: Radius.circular(18),
                                        bottomRight: Radius.circular(18),
                                        bottomLeft: Radius.circular(4),
                                      ),
                                      border: Border.all(
                                        color: AppColors.gray200,
                                      ),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        ShimmerBox(width: 200, height: 10),
                                        SizedBox(height: 6),
                                        ShimmerBox(width: 160, height: 10),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: ChatBubble(message: s.messages[i]),
                        );
                      },
                    ),
                  ),
                  if (showSuggestions)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                      child: SuggestedChips(
                        prompts: prompts,
                        onTap: cubit.send,
                      ),
                    ),
                  ChatInput(
                    onSubmit: cubit.send,
                    canSend: !s.typing,
                  ),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.onHistory, required this.onNew});
  final VoidCallback onHistory;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Pill(label: T.of(context, 'common.online'), tone: PillTone.green),
        const SizedBox(width: 6),
        _IconBtn(
          icon: PhosphorIconsRegular.clockCounterClockwise,
          tooltip: T.of(context, 'chat.history'),
          onTap: onHistory,
        ),
        const SizedBox(width: 4),
        _IconBtn(
          icon: PhosphorIconsRegular.plus,
          tooltip: T.of(context, 'chat.newChat'),
          onTap: onNew,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.brand100,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: AppColors.brand, size: 18),
          ),
        ),
      ),
    );
  }
}
