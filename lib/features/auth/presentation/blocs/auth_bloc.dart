import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/register_driver_use_case.dart';
import '../../domain/usecases/register_student_use_case.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterDriverUseCase registerDriverUseCase;
  final RegisterStudentUseCase registerStudentUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerDriverUseCase,
    required this.registerStudentUseCase,
  }) : super(AuthInitial()) {
    
    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      final result = await loginUseCase(LoginParams(email: event.email, password: event.password));
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (token) => emit(AuthAuthenticated(token)),
      );
    });

    on<RegisterStudentEvent>((event, emit) async {
      emit(AuthLoading());
      final result = await registerStudentUseCase(
        username: event.username, firstName: event.firstName, lastName: event.lastName,
        email: event.email, password: event.password, phoneNumber: event.phoneNumber,
        universityName: event.universityName, tiuPhoto: event.tiuPhoto,
      );
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (token) => emit(AuthAuthenticated(token)),
      );
    });

    on<RegisterDriverEvent>((event, emit) async {
      emit(AuthLoading());
      final result = await registerDriverUseCase(RegisterDriverParams(
        username: event.username, firstName: event.firstName, lastName: event.lastName,
        email: event.email, password: event.password, phone: event.phoneNumber,
        dni: event.dni, license: event.licenseNumber, cul: event.culCertificate,
      ));
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (token) => emit(AuthAuthenticated(token)),
      );
    });
  }
}