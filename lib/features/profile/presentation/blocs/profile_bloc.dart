import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/update_student_profile_use_case.dart';
import '../../domain/usecases/update_driver_profile_use_case.dart';

// --- Events ---
abstract class ProfileEvent {}
class LoadProfileEvent extends ProfileEvent {}
class UpdateStudentProfileEvent extends ProfileEvent {
  final String firstName, lastName, phoneNumber;
  UpdateStudentProfileEvent({required this.firstName, required this.lastName, required this.phoneNumber});
}
class UpdateDriverProfileEvent extends ProfileEvent {
  final String firstName, lastName, phoneNumber, cardNumber, vehicleType, vehicleName, vehiclePlate;
  UpdateDriverProfileEvent({
    required this.firstName, required this.lastName, required this.phoneNumber,
    required this.cardNumber, required this.vehicleType, required this.vehicleName, required this.vehiclePlate,
  });
}

// --- States ---
abstract class ProfileState {}
class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileUpdating extends ProfileState {} // New state for showing loading during update
class ProfileLoaded extends ProfileState {
  final User userData;
  ProfileLoaded(this.userData);
}
class ProfileUpdateSuccess extends ProfileState {
  final User userData;
  ProfileUpdateSuccess(this.userData);
}
class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

// --- Bloc ---
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final UpdateStudentProfileUseCase updateStudentUseCase;
  final UpdateDriverProfileUseCase updateDriverUseCase;

  ProfileBloc({
    required this.getCurrentUserUseCase,
    required this.updateStudentUseCase,
    required this.updateDriverUseCase,
  }) : super(ProfileInitial()) {
    
    on<LoadProfileEvent>((event, emit) async {
      emit(ProfileLoading());
      final result = await getCurrentUserUseCase(NoParams()); 
      result.fold(
        (failure) => emit(ProfileError(failure.message)),
        (user) => emit(ProfileLoaded(user)),
      );
    });

    on<UpdateStudentProfileEvent>((event, emit) async {
      emit(ProfileUpdating());
      final result = await updateStudentUseCase(UpdateStudentParams(
        firstName: event.firstName,
        lastName: event.lastName,
        phoneNumber: event.phoneNumber,
      ));
      result.fold(
        (failure) => emit(ProfileError(failure.message)),
        (user) => emit(ProfileUpdateSuccess(user)),
      );
    });

    on<UpdateDriverProfileEvent>((event, emit) async {
      emit(ProfileUpdating());
      final result = await updateDriverUseCase(UpdateDriverParams(
        firstName: event.firstName,
        lastName: event.lastName,
        phoneNumber: event.phoneNumber,
        cardNumber: event.cardNumber,
        vehicleType: event.vehicleType,
        vehicleName: event.vehicleName,
        vehiclePlate: event.vehiclePlate,
      ));
      result.fold(
        (failure) => emit(ProfileError(failure.message)),
        (user) => emit(ProfileUpdateSuccess(user)),
      );
    });
  }
}
