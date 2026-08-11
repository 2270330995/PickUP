import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../data/vehicle_api.dart';

/// Bottom sheet a driver uses to pick (or clear) the vehicle they will use
/// for a specific event. Returns the selected vehicle's id (or null if the
/// driver chose "Clear selection"). Returns nothing if the sheet was dismissed.
Future<VehicleSheetResult?> showVehiclePickerSheet(
  BuildContext context, {
  String? currentVehicleId,
  bool allowClear = true,
}) async {
  return showModalBottomSheet<VehicleSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _VehiclePickerSheet(
      currentVehicleId: currentVehicleId,
      allowClear: allowClear,
    ),
  );
}

/// Wrapper so callers can disambiguate "user picked null to clear" from "sheet was dismissed".
class VehicleSheetResult {
  const VehicleSheetResult(this.vehicleId);
  final String? vehicleId;
}

class _VehiclePickerSheet extends ConsumerWidget {
  const _VehiclePickerSheet({
    required this.currentVehicleId,
    required this.allowClear,
  });
  final String? currentVehicleId;
  final bool allowClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(myVehiclesProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose your vehicle',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: vehiclesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(err is ApiException
                      ? err.message
                      : 'Failed to load vehicles'),
                ),
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "You don't have any vehicles yet. Add one first.",
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add a vehicle'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.push(RoutePaths.vehicleNew);
                            },
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: vehicles.length,
                    itemBuilder: (_, i) {
                      final v = vehicles[i];
                      final selected = v.id == currentVehicleId;
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          title: Text('${v.make} ${v.model}'),
                          subtitle: Text([
                            if (v.color != null && v.color!.isNotEmpty) v.color!,
                            if (v.plate != null && v.plate!.isNotEmpty) v.plate!,
                            '${v.seats} seats',
                          ].join(' · ')),
                          onTap: () => Navigator.of(context)
                              .pop(VehicleSheetResult(v.id)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (allowClear && currentVehicleId != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Clear selection'),
                onPressed: () =>
                    Navigator.of(context).pop(const VehicleSheetResult(null)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
