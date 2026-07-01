import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/auth/session_expired_handler.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/cubit/admin_cubit.dart';
import 'features/admin/presentation/pages/admin_page.dart';
import 'features/auth/domain/auth_domain.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/chat/presentation/cubit/chat_cubit.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'features/chat/presentation/widgets/chat_bot_floating_button.dart';
import 'features/invoices/presentation/cubit/invoice_cubit.dart';
import 'features/invoices/presentation/pages/invoice_extractor_page.dart';
import 'features/tenders/presentation/cubit/tenders_cubit.dart';
import 'features/tenders/presentation/pages/tender_details_page.dart';
import 'features/tenders/presentation/pages/tenders_page.dart';
import 'injection_container.dart';

import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      title: "Tender MU System",
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const TenderManagementApp());
}

class TenderManagementApp extends StatelessWidget {
  const TenderManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 1024),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp.router(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: const [
                Breakpoint(start: 0, end: 599, name: MOBILE),
                Breakpoint(start: 600, end: 1023, name: TABLET),
                Breakpoint(start: 1024, end: double.infinity, name: DESKTOP),
              ],
            ),
          );
        },
        routerConfig: _router,
      ),
    );
  }
}

final _router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppConstants.loginPath,
  redirect: (context, state) {
    final isLoginRoute = state.uri.path == AppConstants.loginPath;
    final isAdminRoute = state.uri.path == AppConstants.adminPath;
    final isAuthenticated = sl<AuthRepository>().isAuthenticated;
    if (!isAuthenticated && !isLoginRoute) return AppConstants.loginPath;
    if (isAuthenticated && isLoginRoute) {
      final role = sl<AuthRepository>().userRole;
      if (role?.toUpperCase() == 'ADMIN') return AppConstants.adminPath;
      return AppConstants.tendersPath;
    }
    if (isAdminRoute && isAuthenticated) {
      final role = sl<AuthRepository>().userRole;
      if (role?.toUpperCase() != 'ADMIN') return AppConstants.tendersPath;
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, _) => AppConstants.loginPath),
    GoRoute(
      path: AppConstants.loginPath,
      pageBuilder: (context, state) => _transitionPage(
        state,
        BlocProvider(create: (_) => sl<AuthCubit>(), child: const LoginPage()),
      ),
    ),
    GoRoute(
      path: AppConstants.adminPath,
      pageBuilder: (context, state) {
        final repo = sl<AuthRepository>();
        final userName = repo.currentUserName ?? 'مدير';
        final role = repo.userRole ?? 'ADMIN';
        return _transitionPage(
          state,
          MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<AdminCubit>()),
              BlocProvider(create: (_) => sl<AuthCubit>()),
            ],
            child: AdminPage(userName: userName, role: role),
          ),
        );
      },
    ),
    ShellRoute(
      builder: (context, state, child) => ChatBotShell(
        showChatButton: state.uri.path != AppConstants.chatPath,
        child: child,
      ),
      routes: [
        GoRoute(
          path: AppConstants.tendersPath,
          pageBuilder: (context, state) => _transitionPage(
            state,
            BlocProvider(
              create: (_) => sl<TendersCubit>()..loadTenders(),
              child: const TendersPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppConstants.invoiceExtractorPath,
          pageBuilder: (context, state) => _transitionPage(
            state,
            BlocProvider(
              create: (_) => sl<InvoiceCubit>(),
              child: const InvoiceExtractorPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppConstants.chatPath,
          pageBuilder: (context, state) => _transitionPage(
            state,
            BlocProvider(
              create: (_) => sl<ChatCubit>(),
              child: const ChatPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppConstants.tenderDetailsPath,
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return _transitionPage(
              state,
              BlocProvider(
                create: (_) => sl<TenderDetailsCubit>()..loadTender(id),
                child: TenderDetailsPage(tenderId: id),
              ),
            );
          },
        ),
      ],
    ),
  ],
);

CustomTransitionPage<void> _transitionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: .98, end: 1).animate(curve),
          child: child,
        ),
      );
    },
  );
}
