import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../constants/api_constants.dart';
import '../network/jwt_interceptor.dart';

// Auth Feature
import '../../features/auth/data/services/auth_api_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_use_case.dart';
import '../../features/auth/domain/usecases/register_driver_use_case.dart';
import '../../features/auth/domain/usecases/register_student_use_case.dart';
import '../../features/auth/presentation/blocs/auth_bloc.dart';

// Onboarding Feature
import '../../features/onboarding/data/services/onboarding_api_service.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/link_payment_card_use_case.dart';
import '../../features/onboarding/domain/usecases/register_vehicle_use_case.dart';
import '../../features/onboarding/presentation/blocs/onboarding_bloc.dart';

// Profile Feature
import '../../features/profile/data/services/profile_api_service.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_current_user_use_case.dart';
import '../../features/profile/domain/usecases/update_student_profile_use_case.dart';
import '../../features/profile/domain/usecases/update_driver_profile_use_case.dart';
import '../../features/profile/presentation/blocs/profile_bloc.dart';

// Routes Feature
import '../../features/routes/data/services/routes_api_service.dart';
import '../../features/routes/data/repositories/routes_repository_impl.dart';
import '../../features/routes/domain/repositories/routes_repository.dart';
import '../../features/routes/domain/usecases/create_route_and_booking_use_case.dart';
import '../../features/routes/domain/usecases/search_nearby_bookings_use_case.dart';
import '../../features/routes/domain/usecases/join_booking_use_case.dart';
import '../../features/routes/presentation/blocs/routes_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core / External
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

  // Services / DataSources
  sl.registerLazySingleton(() => AuthApiService(sl()));
  sl.registerLazySingleton(() => OnboardingApiService(sl()));
  sl.registerLazySingleton(() => ProfileApiService(sl()));
  sl.registerLazySingleton(() => RoutesApiService(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(apiService: sl(), secureStorage: sl()),
  );
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<RoutesRepository>(
    () => RoutesRepositoryImpl(apiService: sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterStudentUseCase(sl()));
  sl.registerLazySingleton(() => RegisterDriverUseCase(sl()));
  
  sl.registerLazySingleton(() => RegisterVehicleUseCase(sl()));
  sl.registerLazySingleton(() => LinkPaymentCardUseCase(sl()));
  
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdateStudentProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDriverProfileUseCase(sl()));

  sl.registerLazySingleton(() => CreateRouteAndBookingUseCase(sl()));
  sl.registerLazySingleton(() => SearchNearbyBookingsUseCase(sl()));
  sl.registerLazySingleton(() => JoinBookingUseCase(sl()));

  // Blocs
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

  sl.registerFactory(() => RoutesBloc(
        createRouteAndBookingUseCase: sl(),
        searchNearbyBookingsUseCase: sl(),
        joinBookingUseCase: sl(),
      ));
}
