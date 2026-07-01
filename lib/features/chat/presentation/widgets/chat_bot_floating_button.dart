import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class ChatBotShell extends StatelessWidget {
  const ChatBotShell({
    super.key,
    required this.child,
    required this.showChatButton,
  });

  final Widget child;
  final bool showChatButton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showChatButton)
          PositionedDirectional(
            end: 26.w,
            bottom: 26.h,
            child: const ChatBotFloatingButton(),
          ),
      ],
    );
  }
}

class ChatBotFloatingButton extends StatefulWidget {
  const ChatBotFloatingButton({super.key});

  @override
  State<ChatBotFloatingButton> createState() => _ChatBotFloatingButtonState();
}

class _ChatBotFloatingButtonState extends State<ChatBotFloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
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
        final lift = -4 * _controller.value;
        final glow = .16 + (_controller.value * .16);
        return Transform.translate(
          offset: Offset(0, lift),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: glow),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(AppConstants.chatPath),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: .45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10.w),
                const Text(
                  'تحدث مع البوت',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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
