import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_drawer.dart';
import '../../../profile/presentation/blocs/profile_bloc.dart';
import '../../../routes/presentation/pages/driver_home_page.dart';
import '../../../routes/presentation/pages/student_home_page.dart';

class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Cargar perfil del usuario actual para saber su rol (DRIVER o STUDENT)
    context.read<ProfileBloc>().add(LoadProfileEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        } else if (state is ProfileLoaded) {
          final role = state.userData.role.toUpperCase();
          if (role == 'DRIVER') {
            return const DriverHomePage();
          } else {
            return const Scaffold(
              drawer: CustomDrawer(),
              body: StudentHomePage(),
            );
          }
        } else if (state is ProfileError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error al cargar perfil: ${state.message}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProfileBloc>().add(LoadProfileEvent());
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      },
    );
  }
}
