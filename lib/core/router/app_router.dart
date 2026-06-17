import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/splash_screen_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/auth/presentation/pages/student_registration_page.dart';
import '../../features/auth/presentation/pages/driver_registration_page.dart';
import '../../features/auth/presentation/pages/main_dashboard_page.dart'; 
import '../../features/profile/presentation/pages/profile_page.dart';

import '../../features/onboarding/presentation/pages/vehicle_form_page.dart';
import '../../features/onboarding/presentation/pages/link_card_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreenPage());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginPage());
      case '/role-selection':
        return MaterialPageRoute(builder: (_) => const RoleSelectionPage());
      case '/register-student':
        return MaterialPageRoute(builder: (_) => const StudentRegistrationPage());
      case '/register-driver':
        return MaterialPageRoute(builder: (_) => const DriverRegistrationPage());
        
      case '/register-vehicle':
        return MaterialPageRoute(builder: (_) => const VehicleFormPage());
      case '/link-card':
        return MaterialPageRoute(builder: (_) => const LinkCardPage());
        
      case '/home':
        return MaterialPageRoute(builder: (_) => const MainDashboardPage());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No existe la ruta: ${settings.name}')),
          ),
        );
    }
  }
}