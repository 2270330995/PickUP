import '../../participant/data/participant_dtos.dart';

/// A person on the organizer's reusable People roster. Not tied to a
/// registered PickUP account — see backend `ContactEntity` (Phase 4D-1).
class ContactResponse {
  const ContactResponse({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.defaultAddress,
    this.defaultLat,
    this.defaultLng,
    this.notes,
    this.preferredRole,
    required this.vehicleCount,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? defaultAddress;
  final double? defaultLat;
  final double? defaultLng;
  final String? notes;
  final ParticipantRole? preferredRole;
  final int vehicleCount;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasDefaultLocation => defaultAddress != null && defaultAddress!.isNotEmpty;

  factory ContactResponse.fromJson(Map<String, dynamic> json) {
    final roleRaw = json['preferredRole'] as String?;
    return ContactResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      defaultAddress: json['defaultAddress'] as String?,
      defaultLat: (json['defaultLat'] as num?)?.toDouble(),
      defaultLng: (json['defaultLng'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      preferredRole: roleRaw == null ? null : participantRoleFromString(roleRaw),
      vehicleCount: (json['vehicleCount'] as num?)?.toInt() ?? 0,
      archivedAt: json['archivedAt'] == null ? null : DateTime.parse(json['archivedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Case-insensitive substring match against name/phone/email/default address
/// — shared by the People roster search and the "Add from People" picker so
/// both search the same fields the same way.
bool contactMatchesQuery(ContactResponse contact, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return contact.name.toLowerCase().contains(q) ||
      (contact.phone?.toLowerCase().contains(q) ?? false) ||
      (contact.email?.toLowerCase().contains(q) ?? false) ||
      (contact.defaultAddress?.toLowerCase().contains(q) ?? false);
}

class CreateContactRequest {
  const CreateContactRequest({
    required this.name,
    this.phone,
    this.email,
    this.defaultAddress,
    this.defaultLat,
    this.defaultLng,
    this.notes,
    this.preferredRole,
  });

  final String name;
  final String? phone;
  final String? email;
  final String? defaultAddress;
  final double? defaultLat;
  final double? defaultLng;
  final String? notes;
  final ParticipantRole? preferredRole;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (defaultAddress != null && defaultAddress!.isNotEmpty) 'defaultAddress': defaultAddress,
        if (defaultLat != null) 'defaultLat': defaultLat,
        if (defaultLng != null) 'defaultLng': defaultLng,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (preferredRole != null) 'preferredRole': participantRoleToString(preferredRole!),
      };
}

class UpdateContactRequest {
  const UpdateContactRequest({
    this.name,
    this.phone,
    this.email,
    this.defaultAddress,
    this.defaultLat,
    this.defaultLng,
    this.notes,
    this.preferredRole,
  });

  final String? name;
  final String? phone;
  final String? email;
  final String? defaultAddress;
  final double? defaultLat;
  final double? defaultLng;
  final String? notes;
  final ParticipantRole? preferredRole;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (defaultAddress != null) 'defaultAddress': defaultAddress,
        if (defaultLat != null) 'defaultLat': defaultLat,
        if (defaultLng != null) 'defaultLng': defaultLng,
        if (notes != null) 'notes': notes,
        if (preferredRole != null) 'preferredRole': participantRoleToString(preferredRole!),
      };
}

/// A vehicle reusable across events, owned by a Contact (usually a driver).
class ContactVehicleResponse {
  const ContactVehicleResponse({
    required this.id,
    required this.contactId,
    required this.label,
    this.make,
    this.model,
    this.color,
    this.plate,
    required this.seats,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String contactId;
  final String label;
  final String? make;
  final String? model;
  final String? color;
  final String? plate;
  final int seats;
  final String? notes;
  final DateTime createdAt;

  /// Prefers the mandatory [label]; only falls back to make/model/color/plate
  /// for records that somehow have a blank label (shouldn't happen once the
  /// backend enforces it, but keeps display robust either way).
  String get displayLabel {
    if (label.isNotEmpty) return label;
    final parts = <String>[];
    final makeModel = [make, model].where((s) => s != null && s.isNotEmpty).join(' ');
    if (makeModel.isNotEmpty) parts.add(makeModel);
    if (color != null && color!.isNotEmpty) parts.add(color!);
    if (plate != null && plate!.isNotEmpty) parts.add(plate!);
    return parts.isEmpty ? 'Vehicle' : parts.join(' · ');
  }

  factory ContactVehicleResponse.fromJson(Map<String, dynamic> json) {
    return ContactVehicleResponse(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      label: json['label'] as String? ?? '',
      make: json['make'] as String?,
      model: json['model'] as String?,
      color: json['color'] as String?,
      plate: json['plate'] as String?,
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class CreateContactVehicleRequest {
  const CreateContactVehicleRequest({
    required this.label,
    this.make,
    this.model,
    this.color,
    this.plate,
    required this.seats,
    this.notes,
  });

  final String label;
  final String? make;
  final String? model;
  final String? color;
  final String? plate;
  final int seats;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'label': label,
        if (make != null && make!.isNotEmpty) 'make': make,
        if (model != null && model!.isNotEmpty) 'model': model,
        if (color != null && color!.isNotEmpty) 'color': color,
        if (plate != null && plate!.isNotEmpty) 'plate': plate,
        'seats': seats,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

class UpdateContactVehicleRequest {
  const UpdateContactVehicleRequest({
    this.label,
    this.make,
    this.model,
    this.color,
    this.plate,
    this.seats,
    this.notes,
  });

  final String? label;
  final String? make;
  final String? model;
  final String? color;
  final String? plate;
  final int? seats;
  final String? notes;

  Map<String, dynamic> toJson() => {
        if (label != null) 'label': label,
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (color != null) 'color': color,
        if (plate != null) 'plate': plate,
        if (seats != null) 'seats': seats,
        if (notes != null) 'notes': notes,
      };
}
