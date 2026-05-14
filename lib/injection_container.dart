import 'package:get_it/get_it.dart';

import 'core/network/api_client.dart';
import 'features/tenders/data/datasource/tender_remote_datasource.dart';
import 'features/tenders/data/repositories/tender_repository_impl.dart';
import 'features/tenders/domain/tender_domain.dart';
import 'features/tenders/presentation/cubit/tenders_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl
    ..registerLazySingleton<ApiClient>(ApiClient.new)
    ..registerLazySingleton(() => sl<ApiClient>().dio)
    ..registerLazySingleton<TenderRemoteDataSource>(() => TenderRemoteDataSource(sl()))
    ..registerLazySingleton<TenderRepository>(() => TenderRepositoryImpl(sl()))
    ..registerFactory(() => TendersCubit(sl()))
    ..registerFactory(() => TenderDetailsCubit(sl()));
}
