import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/tenders/presentation/cubit/tenders_cubit.dart';
import 'features/tenders/presentation/pages/tender_details_page.dart';
import 'features/tenders/presentation/pages/tenders_page.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
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
  initialLocation: AppConstants.tendersPath,
  routes: [
    GoRoute(path: '/', redirect: (_, __) => AppConstants.tendersPath),
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
);

CustomTransitionPage<void> _transitionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(scale: Tween<double>(begin: .98, end: 1).animate(curve), child: child),
      );
    },
  );
}
