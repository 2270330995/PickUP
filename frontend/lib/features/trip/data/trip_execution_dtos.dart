// DTOs for Phase 3B trip execution (start / complete / updateStop).
// Kept separate from trip_dtos.dart (read model vs driver write actions).

enum StopAction { pickUp, skip, cancel }

String stopActionToString(StopAction a) {
  switch (a) {
    case StopAction.pickUp:
      return 'PICK_UP';
    case StopAction.skip:
      return 'SKIP';
    case StopAction.cancel:
      return 'CANCEL';
  }
}

String stopActionLabel(StopAction a) {
  switch (a) {
    case StopAction.pickUp:
      return 'Picked up';
    case StopAction.skip:
      return 'Skip (no-show)';
    case StopAction.cancel:
      return 'Cancel stop';
  }
}

class UpdateTripStopRequest {
  const UpdateTripStopRequest({required this.action});

  final StopAction action;

  Map<String, dynamic> toJson() => {'action': stopActionToString(action)};
}
