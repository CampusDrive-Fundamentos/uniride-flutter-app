import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart'; // Para importar NoParams
import '../../../auth/domain/entities/user.dart';
import '../../domain/usecases/get_current_user_use_case.dart';

abstract class ProfileState {}
class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileLoaded extends ProfileState {
  final User userData;
  ProfileLoaded(this.userData);
}
class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileBloc extends Bloc<dynamic, ProfileState> {
  final GetCurrentUserUseCase getCurrentUserUseCase;

  ProfileBloc(this.getCurrentUserUseCase) : super(ProfileInitial()) {
    on<String>((event, emit) async {
      if (event == 'LoadProfile') {
        emit(ProfileLoading());
        final result = await getCurrentUserUseCase(NoParams()); 
        result.fold(
          (failure) => emit(ProfileError(failure.message)),
          (user) => emit(ProfileLoaded(user)),
        );
      }
    });
  }
}