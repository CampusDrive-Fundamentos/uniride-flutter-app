import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../constants/api_constants.dart';
import '../network/jwt_interceptor.dart';

// --- Auth Imports ---
import '../../features/auth/data/services/auth_api_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_use_case.dart';
import '../../features/auth/domain/usecases/register_driver_use_case.dart';
import '../../features/auth/domain/usecases/register_student_use_case.dart';
import '../../features/auth/presentation/blocs/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ));
    dio.interceptors.add(JwtInterceptor(secureStorage: sl()));
    return dio;
  });

  sl.registerLazySingleton(() => AuthApiService(sl()));
  // sl.registerLazySingleton(() => OnboardingApiService(sl()));
  // sl.registerLazySingleton(() => ProfileApiService(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(apiService: sl(), secureStorage: sl()),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterStudentUseCase(sl()));
  sl.registerLazySingleton(() => RegisterDriverUseCase(sl()));

  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl(),
        registerDriverUseCase: sl(),
        registerStudentUseCase: sl(), 
      ));
}