import 'package:get_it/get_it.dart';

import 'core/auth/auth_token_store.dart';
import 'core/auth/session_expired_handler.dart';
import 'core/network/api_client.dart';
import 'features/admin/data/datasource/admin_remote_datasource.dart';
import 'features/admin/data/repositories/admin_repository_impl.dart';
import 'features/admin/domain/admin_domain.dart';
import 'features/admin/presentation/cubit/admin_cubit.dart';
import 'features/auth/data/datasource/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/auth_domain.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/chat/data/datasource/chat_remote_datasource.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/chat_domain.dart';
import 'features/chat/presentation/cubit/chat_cubit.dart';
import 'features/invoices/data/datasource/invoice_remote_datasource.dart';
import 'features/invoices/data/repositories/invoice_repository_impl.dart';
import 'features/invoices/domain/invoice_domain.dart';
import 'features/invoices/presentation/cubit/invoice_cubit.dart';
import 'features/tenders/data/datasource/tender_remote_datasource.dart';
import 'features/tenders/data/repositories/tender_repository_impl.dart';
import 'features/tenders/domain/tender_domain.dart';
import 'features/tenders/presentation/cubit/tenders_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl
    ..registerLazySingleton<AuthTokenStore>(AuthTokenStore.new)
    ..registerLazySingleton<SessionExpiredHandler>(
      () => SessionExpiredHandler(
        navigatorKey: rootNavigatorKey,
        tokenStore: sl(),
      ),
    )
    ..registerLazySingleton<ApiClient>(() => ApiClient(sl(), sl()))
    ..registerLazySingleton(() => sl<ApiClient>().dio)
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl()),
    )
    ..registerFactory(() => AuthCubit(sl()))
    ..registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSource(sl()),
    )
    ..registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()))
    ..registerFactory(() => ChatCubit(sl()))
    ..registerLazySingleton<TenderRemoteDataSource>(
      () => TenderRemoteDataSource(sl()),
    )
    ..registerLazySingleton<TenderRepository>(() => TenderRepositoryImpl(sl()))
    ..registerLazySingleton<InvoiceRemoteDataSource>(
      () => InvoiceRemoteDataSource(sl()),
    )
    ..registerLazySingleton<InvoiceRepository>(
      () => InvoiceRepositoryImpl(sl()),
    )
    ..registerFactory(() => TendersCubit(sl()))
    ..registerFactory(() => InvoiceCubit(sl()))
    ..registerFactory(() => TenderDetailsCubit(sl()))
    ..registerLazySingleton<AdminRemoteDataSource>(
      () => AdminRemoteDataSource(sl()),
    )
    ..registerLazySingleton<AdminRepository>(
      () => AdminRepositoryImpl(sl()),
    )
    ..registerFactory(() => AdminCubit(sl()));
}
