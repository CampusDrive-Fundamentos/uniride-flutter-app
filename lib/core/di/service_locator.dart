import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../constants/api_constants.dart';
import '../network/jwt_interceptor.dart';

import '../../features/auth/data/services/auth_api_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_use_case.dart';
import '../../features/auth/domain/usecases/register_driver_use_case.dart';
import '../../features/auth/domain/usecases/register_student_use_case.dart';
import '../../features/auth/presentation/blocs/auth_bloc.dart';

import '../../features/onboarding/data/services/onboarding_api_service.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/link_payment_card_use_case.dart';
import '../../features/onboarding/domain/usecases/register_vehicle_use_case.dart';
import '../../features/onboarding/presentation/blocs/onboarding_bloc.dart';

import '../../features/profile/data/services/profile_api_service.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_current_user_use_case.dart';
import '../../features/profile/domain/usecases/update_student_profile_use_case.dart';
import '../../features/profile/domain/usecases/update_driver_profile_use_case.dart';
import '../../features/profile/presentation/blocs/profile_bloc.dart';

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
  sl.registerLazySingleton(() => OnboardingApiService(sl()));
  sl.registerLazySingleton(() => ProfileApiService(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(apiService: sl(), secureStorage: sl()),
  );
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterStudentUseCase(sl()));
  sl.registerLazySingleton(() => RegisterDriverUseCase(sl()));
  
  sl.registerLazySingleton(() => RegisterVehicleUseCase(sl()));
  sl.registerLazySingleton(() => LinkPaymentCardUseCase(sl()));
  
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdateStudentProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDriverProfileUseCase(sl()));

  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl(),
        registerDriverUseCase: sl(),
        registerStudentUseCase: sl(), 
      ));
      
  sl.registerFactory(() => OnboardingBloc(
        registerVehicleUseCase: sl(),
        linkPaymentCardUseCase: sl(),
      ));
      
  sl.registerFactory(() => ProfileBloc(
        getCurrentUserUseCase: sl(),
        updateStudentUseCase: sl(),
        updateDriverUseCase: sl(),
      ));
}
