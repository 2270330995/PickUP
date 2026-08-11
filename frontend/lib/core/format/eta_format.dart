/// Formats ETA minutes for trip planning displays.
String? formatEtaMinutes(int? etaMinutes, {String prefix = '~'}) {
  if (etaMinutes == null || etaMinutes <= 0) return null;
  return '$prefix$etaMinutes min from start';
}

String? formatEtaMinutesShort(int? etaMinutes) {
  if (etaMinutes == null || etaMinutes <= 0) return null;
  return '~$etaMinutes min';
}

int? maxEtaMinutes(Iterable<int?> values) {
  int? max;
  for (final value in values) {
    if (value == null) continue;
    if (max == null || value > max) max = value;
  }
  return max;
}
