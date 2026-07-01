import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/chat_domain.dart';
import '../cubit/chat_cubit.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          previous.messages.length != current.messages.length ||
          previous.status != current.status,
      listener: (_, _) => _scrollToBottom(),
      builder: (context, state) {
        final isMobile = ResponsiveBreakpoints.of(context).smallerThan(TABLET);
        return Scaffold(
          body: ResponsivePage(
            maxWidth: 1020,
            child: Column(
              children: [
                _ChatHeader(isSending: state.status == ChatStatus.sending),
                SizedBox(height: 18.h),
                Expanded(
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Expanded(
                          child: _MessagesList(
                            controller: _scrollController,
                            messages: state.messages,
                            isTyping: state.status == ChatStatus.sending,
                          ),
                        ),
                        _QuickPrompts(
                          onSelected: (message) {
                            _messageController.text = message;
                            _sendMessage();
                          },
                        ),
                        _MessageComposer(
                          controller: _messageController,
                          enabled: state.status != ChatStatus.sending,
                          compact: isMobile,
                          onSend: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final message = _messageController.text;
    _messageController.clear();
    context.read<ChatCubit>().sendMessage(message);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.isSending});

  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(22.r),
      child: Row(
        children: [
          const _AnimatedBotAvatar(size: 58),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مساعد النظام الذكي',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 4.h),
                Text(
                  isSending
                      ? 'يقوم البوت بتحليل رسالتك الآن...'
                      : 'اسأل عن بيانات الموظفين أو العطاءات وسيتم تنفيذ الطلب من الخادم.',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => context.go('/tenders'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('العودة'),
          ),
        ],
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({
    required this.controller,
    required this.messages,
    required this.isTyping,
  });

  final ScrollController controller;
  final List<ChatMessage> messages;
  final bool isTyping;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.all(20.r),
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= messages.length) {
          return const _TypingBubble();
        }
        return _MessageBubble(message: messages[index]);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubbleColor = isUser ? AppColors.primary : AppColors.background;
    final textColor = isUser ? Colors.white : AppColors.text;
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveBreakpoints.of(context).smallerThan(TABLET)
                ? MediaQuery.sizeOf(context).width * .78
                : 620.w,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isUser) ...[
                _BubbleBody(
                  color: bubbleColor,
                  textColor: textColor,
                  content: message.content,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                SizedBox(width: 8.w),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.person_outline, size: 18),
                ),
              ] else ...[
                const _BotMiniAvatar(),
                SizedBox(width: 8.w),
                _BubbleBody(
                  color: bubbleColor,
                  textColor: textColor,
                  content: message.content,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                    bottomRight: Radius.circular(6),
                    bottomLeft: Radius.circular(22),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    required this.color,
    required this.textColor,
    required this.content,
    required this.borderRadius,
  });

  final Color color;
  final Color textColor;
  final String content;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          border: Border.all(
            color: color == AppColors.background
                ? AppColors.border
                : Colors.transparent,
          ),
        ),
        child: SelectableText(
          content,
          style: TextStyle(color: textColor, height: 1.55),
        ),
      ),
    );
  }
}

class _QuickPrompts extends StatelessWidget {
  const _QuickPrompts({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final prompts = [
      'اعرض بيانات الموظف 2030',
      'ما آخر العطاءات؟',
      'ساعدني في البحث عن عطاء',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
      child: Row(
        children: [
          for (final prompt in prompts) ...[
            ActionChip(
              label: Text(prompt),
              avatar: const Icon(Icons.auto_awesome, size: 18),
              onPressed: () => onSelected(prompt),
              backgroundColor: AppColors.primary.withValues(alpha: .07),
              side: BorderSide(color: AppColors.primary.withValues(alpha: .16)),
            ),
            SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.enabled,
    required this.compact,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool compact;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: compact ? 3 : 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => enabled ? onSend() : null,
              decoration: const InputDecoration(
                hintText: 'اكتب رسالتك هنا...',
                prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          FilledButton(
            onPressed: enabled ? onSend : null,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: enabled
                ? const Icon(Icons.send_rounded)
                : SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BotMiniAvatar(),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const _TypingDots(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final value = (_controller.value + (index * .2)) % 1;
            return Container(
              width: 7.r,
              height: 7.r,
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .35 + value * .5),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _AnimatedBotAvatar extends StatefulWidget {
  const _AnimatedBotAvatar({required this.size});

  final double size;

  @override
  State<_AnimatedBotAvatar> createState() => _AnimatedBotAvatarState();
}

class _AnimatedBotAvatarState extends State<_AnimatedBotAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = .96 + (_controller.value * .07);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size.r,
            height: widget.size.r,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .22),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
        );
      },
    );
  }
}

class _BotMiniAvatar extends StatelessWidget {
  const _BotMiniAvatar();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16.r,
      backgroundColor: AppColors.primary.withValues(alpha: .1),
      foregroundColor: AppColors.primary,
      child: const Icon(Icons.smart_toy_outlined, size: 18),
    );
  }
}
