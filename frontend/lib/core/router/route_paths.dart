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

  // Phase 3A — manual trips
  static const vehicles = '/vehicles';
  static const vehicleNew = '/vehicles/new';
  static const vehicleEdit = '/vehicles/:id/edit';
  static const myTrips = '/trips';
  static const manageAssignments = '/events/:id/assignments';
  static const eventTrips = '/events/:id/trips';

  static const driverTrip = '/driver/trips/:tripId';
  static const passengerRide = '/passenger/rides/:tripId';
  static const tripMonitor = '/trips/:tripId/monitor';

  static String eventDetailFor(String eventId) => '/events/$eventId';
  static String driverTripFor(String tripId) => '/driver/trips/$tripId';
  static String passengerRideFor(String tripId) => '/passenger/rides/$tripId';
  static String tripMonitorFor(String tripId) => '/trips/$tripId/monitor';
  static String vehicleEditFor(String vehicleId) => '/vehicles/$vehicleId/edit';
  static String manageAssignmentsFor(String eventId) =>
      '/events/$eventId/assignments';
  static String eventTripsFor(String eventId) => '/events/$eventId/trips';
}
