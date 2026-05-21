import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/driver/presentation/driver_trip_screen.dart';
import '../../features/event/presentation/browse_events_screen.dart';
import '../../features/event/presentation/create_event_screen.dart';
import '../../features/event/presentation/event_detail_screen.dart';
import '../../features/organizer/presentation/organizer_dashboard_screen.dart';
import '../../features/passenger/presentation/passenger_ride_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../shared/providers/auth_provider.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isSplash = loc == RoutePaths.splash;
      final isLogin = loc == RoutePaths.login;
      final isRegister = loc == RoutePaths.register;

      if (auth.isLoading) {
        return isSplash ? null : RoutePaths.splash;
      }
      if (!auth.isAuthenticated) {
        if (isLogin || isRegister) return null;
        return RoutePaths.login;
      }
      if (isLogin || isRegister || isSplash) {
        return RoutePaths.organizer;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.organizer,
        builder: (_, __) => const OrganizerDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.browseEvents,
        builder: (_, __) => const BrowseEventsScreen(),
      ),
      GoRoute(
        path: RoutePaths.createEvent,
        builder: (_, __) => const CreateEventScreen(),
      ),
      GoRoute(
        path: RoutePaths.eventDetail,
        builder: (_, state) => EventDetailScreen(
          eventId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.driverTrip,
        builder: (_, state) => DriverTripScreen(
          tripId: state.pathParameters['tripId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.passengerRide,
        builder: (_, state) => PassengerRideScreen(
          tripId: state.pathParameters['tripId']!,
        ),
      ),
    ],
  );
});
