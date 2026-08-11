import 'package:flutter/material.dart';

import '../../location/presentation/location_picker_sheet.dart';

/// Bottom sheet for a passenger to set or update their pickup location.
Future<PickupAddressResult?> showPickupAddressSheet(
  BuildContext context, {
  String? currentAddress,
  double? currentLat,
  double? currentLng,
}) async {
  final result = await showLocationPickerSheet(
    context,
    title: 'Pickup location',
    subtitle: 'Where should your driver pick you up?',
    fieldLabel: 'Pickup address',
    currentAddress: currentAddress,
    currentLat: currentLat,
    currentLng: currentLng,
    confirmLabel: 'Save pickup location',
  );
  if (result == null) return null;
  return PickupAddressResult(
    pickupAddress: result.formattedAddress,
    pickupLat: result.lat,
    pickupLng: result.lng,
  );
}

class PickupAddressResult {
  const PickupAddressResult({
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
  });

  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
}

/// Bottom sheet for a driver to set or update their trip start location.
Future<PickupAddressResult?> showTripStartAddressSheet(
  BuildContext context, {
  String? currentAddress,
  double? currentLat,
  double? currentLng,
}) async {
  final result = await showLocationPickerSheet(
    context,
    title: 'Trip start location',
    subtitle: 'Where will you begin the pickup route?',
    fieldLabel: 'Departure address',
    currentAddress: currentAddress,
    currentLat: currentLat,
    currentLng: currentLng,
    confirmLabel: 'Save trip start',
  );
  if (result == null) return null;
  return PickupAddressResult(
    pickupAddress: result.formattedAddress,
    pickupLat: result.lat,
    pickupLng: result.lng,
  );
}
