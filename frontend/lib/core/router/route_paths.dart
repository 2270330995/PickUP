class RoutePaths {
  RoutePaths._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const profile = '/profile';
  static const organizer = '/organizer';
  static const browseEvents = '/events';
  static const createEvent = '/events/new';
  static const eventDetail = '/events/:id';
  static const driverTrip = '/driver/trips/:tripId';
  static const passengerRide = '/passenger/rides/:tripId';

  static String eventDetailFor(String eventId) => '/events/$eventId';
  static String driverTripFor(String tripId) => '/driver/trips/$tripId';
  static String passengerRideFor(String tripId) => '/passenger/rides/$tripId';
}
