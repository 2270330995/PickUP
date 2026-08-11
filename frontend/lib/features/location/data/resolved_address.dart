/// Resolved address from Google Places selection.
class ResolvedAddress {
  const ResolvedAddress({
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });

  final String formattedAddress;
  final double lat;
  final double lng;
}
