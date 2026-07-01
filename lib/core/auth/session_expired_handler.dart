import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import 'auth_token_store.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class SessionExpiredHandler {
  SessionExpiredHandler({
    required this.navigatorKey,
    required AuthTokenStore tokenStore,
  }) : _tokenStore = tokenStore;

  final GlobalKey<NavigatorState> navigatorKey;
  final AuthTokenStore _tokenStore;

  bool _dialogVisible = false;

  void handleUnauthorized({required int? statusCode, required String path}) {
    if (_dialogVisible) return;
    if (_isLoginRequest(path)) return;
    if (!_tokenStore.hasToken) return;

    _dialogVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDialog(statusCode);
    });
  }

  bool _isLoginRequest(String path) {
    final normalized = path.toLowerCase();
    return normalized.contains('/auth/login');
  }

  Future<void> _showDialog(int? statusCode) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _dialogVisible = false;
      return;
    }

    final message = statusCode == 403
        ? 'تم تسجيل الدخول من جهاز أو مكان آخر. يرجى تسجيل الدخول مرة أخرى.'
        : 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.';

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('انتهت الجلسة'),
              content: Text(message),
              actions: [
                ElevatedButton(
                  onPressed: () => _logout(dialogContext),
                  child: const Text('خروج'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      _dialogVisible = false;
    }
  }

  Future<void> _logout(BuildContext dialogContext) async {
    await _tokenStore.clearToken();

    if (dialogContext.mounted) {
      Navigator.of(dialogContext, rootNavigator: true).pop();
    }

    final rootContext = navigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      GoRouter.of(rootContext).go(AppConstants.loginPath);
    }
  }
}
