import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assignment/presentation/manage_assignments_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/driver/presentation/driver_trip_screen.dart';
import '../../features/event/presentation/browse_events_screen.dart';
import '../../features/event/presentation/create_event_screen.dart';
import '../../features/event/presentation/event_detail_screen.dart';
import '../../features/organizer/presentation/organizer_dashboard_screen.dart';
import '../../features/passenger/presentation/passenger_ride_screen.dart';
import '../../features/people/data/contact_dtos.dart';
import '../../features/people/presentation/contact_detail_screen.dart';
import '../../features/people/presentation/contact_form_screen.dart';
import '../../features/people/presentation/people_list_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/trip/presentation/event_trips_screen.dart';
import '../../features/trip/presentation/my_trips_screen.dart';
import '../../features/trip/presentation/trip_monitor_screen.dart';
import '../../features/vehicle/data/vehicle_dtos.dart';
import '../../features/vehicle/presentation/vehicle_form_screen.dart';
import '../../features/vehicle/presentation/vehicle_list_screen.dart';
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
        path: RoutePaths.people,
        builder: (_, __) => const PeopleListScreen(),
      ),
      GoRoute(
        path: RoutePaths.peopleNew,
        builder: (_, __) => const ContactFormScreen(),
      ),
      GoRoute(
        path: RoutePaths.peopleDetail,
        builder: (_, state) => ContactDetailScreen(
          contactId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.peopleEdit,
        // The detail screen passes the existing ContactResponse via extra so the
        // form pre-populates without a second round-trip; deep links fall back
        // to a fresh-add form.
        builder: (_, state) {
          final extra = state.extra;
          return ContactFormScreen(
            existing: extra is ContactResponse ? extra : null,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.vehicles,
        builder: (_, __) => const VehicleListScreen(),
      ),
      GoRoute(
        path: RoutePaths.vehicleNew,
        builder: (_, __) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: RoutePaths.vehicleEdit,
        // The list screen passes the existing VehicleResponse via context.push(..., extra: vehicle)
        // so the form pre-populates without a second round-trip. If a user deep-links into
        // this route we silently fall back to a fresh-add form.
        builder: (_, state) {
          final extra = state.extra;
          return VehicleFormScreen(
            existing: extra is VehicleResponse ? extra : null,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.myTrips,
        builder: (_, __) => const MyTripsScreen(),
      ),
      GoRoute(
        path: RoutePaths.manageAssignments,
        builder: (_, state) => ManageAssignmentsScreen(
          eventId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.eventTrips,
        builder: (_, state) => EventTripsScreen(
          eventId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.tripMonitor,
        builder: (_, state) => TripMonitorScreen(
          tripId: state.pathParameters['tripId']!,
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
