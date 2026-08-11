import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../data/vehicle_api.dart';
import '../data/vehicle_dtos.dart';

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(myVehiclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My vehicles')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myVehiclesProvider),
        child: vehiclesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(err is ApiException ? err.message : 'Failed to load vehicles'),
            ],
          ),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.directions_car_outlined, size: 56),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      "You don't have any vehicles yet.\n"
                      "Add one so you can drive for an event.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (_, i) => _VehicleCard(vehicle: vehicles[i]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.vehicleNew),
        icon: const Icon(Icons.add),
        label: const Text('Add vehicle'),
      ),
    );
  }
}

class _VehicleCard extends ConsumerStatefulWidget {
  const _VehicleCard({required this.vehicle});
  final VehicleResponse vehicle;

  @override
  ConsumerState<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends ConsumerState<_VehicleCard> {
  bool _deleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete vehicle?'),
        content: Text(
          'Remove "${widget.vehicle.displayLabel}" from your garage?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await ref.read(vehicleApiProvider).delete(widget.vehicle.id);
      ref.invalidate(myVehiclesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle deleted')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.directions_car)),
        title: Text('${v.make} ${v.model}'),
        subtitle: Text([
          if (v.color != null && v.color!.isNotEmpty) v.color!,
          if (v.plate != null && v.plate!.isNotEmpty) v.plate!,
          '${v.seats} seats',
        ].join(' · ')),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _deleting
                  ? null
                  : () => context.push(RoutePaths.vehicleEditFor(v.id), extra: v),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: _deleting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: _deleting ? null : _confirmDelete,
            ),
          ],
        ),
      ),
    );
  }
}
