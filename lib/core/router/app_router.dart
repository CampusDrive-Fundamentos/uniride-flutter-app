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

// Routes Pages
import '../../features/routes/presentation/pages/create_announcement_page.dart';
import '../../features/routes/presentation/pages/nearby_bookings_page.dart';

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
      
      case '/create-announcement':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => CreateAnnouncementPage(
            initialCampus: args['campus'],
            initialLat: args['lat'],
            initialLng: args['lng'],
          ),
        );
      case '/nearby-bookings':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => NearbyBookingsPage(
            campus: args['campus'] ?? 'MONTERRICO',
            lat: args['lat'] ?? -12.1210,
            lng: args['lng'] ?? -77.0290,
          ),
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No existe la ruta: ${settings.name}')),
          ),
        );
    }
  }
}