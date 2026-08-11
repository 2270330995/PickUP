import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../location/data/resolved_address.dart';
import '../../location/presentation/location_picker_sheet.dart';
import '../../participant/data/participant_api.dart';
import '../../participant/data/participant_dtos.dart';
import '../../people/data/contact_api.dart';
import '../../people/data/contact_dtos.dart';

/// Organizer-only bottom sheet to edit a participant's per-event role, pickup
/// location, and (for Contact-backed drivers) vehicle. Event-local only: never
/// writes back to the underlying Contact. Returns true if anything was saved.
Future<bool?> showOrganizerParticipantEditSheet(
  BuildContext context, {
  required String eventId,
  required EventParticipantResponse participant,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _OrganizerParticipantEditSheet(
      eventId: eventId,
      participant: participant,
    ),
  );
}

class _OrganizerParticipantEditSheet extends ConsumerStatefulWidget {
  const _OrganizerParticipantEditSheet({
    required this.eventId,
    required this.participant,
  });
  final String eventId;
  final EventParticipantResponse participant;

  @override
  ConsumerState<_OrganizerParticipantEditSheet> createState() =>
      _OrganizerParticipantEditSheetState();
}

class _OrganizerParticipantEditSheetState
    extends ConsumerState<_OrganizerParticipantEditSheet> {
  late ParticipantRole _role;
  ResolvedAddress? _pickup;
  String? _vehicleId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.participant;
    _role = p.role;
    final address = p.pickupAddress;
    final lat = p.pickupLat;
    final lng = p.pickupLng;
    if (address != null && address.isNotEmpty && lat != null && lng != null) {
      _pickup = ResolvedAddress(formattedAddress: address, lat: lat, lng: lng);
    }
    _vehicleId = p.vehicleId;
  }

  Future<void> _pickLocation() async {
    final result = await showLocationPickerSheet(
      context,
      title: 'Pickup location',
      subtitle: 'Where should this person be picked up?',
      fieldLabel: 'Pickup address',
      currentAddress: _pickup?.formattedAddress,
      currentLat: _pickup?.lat,
      currentLng: _pickup?.lng,
      confirmLabel: 'Use this address',
    );
    if (result == null || !mounted) return;
    setState(() => _pickup = result);
  }

  Future<void> _pickVehicle(List<ContactVehicleResponse> vehicles) async {
    final result = await showModalBottomSheet<_VehicleChoice>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _ContactVehiclePicker(
        vehicles: vehicles,
        currentVehicleId: _vehicleId,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _vehicleId = result.vehicleId);
  }

  Future<void> _save() async {
    final original = widget.participant;
    setState(() => _saving = true);
    try {
      final api = ref.read(participantApiProvider);
      final roleChanged = _role != original.role;
      final pickupChanged = _pickup?.formattedAddress != original.pickupAddress ||
          _pickup?.lat != original.pickupLat ||
          _pickup?.lng != original.pickupLng;
      if (roleChanged || pickupChanged) {
        await api.organizerUpdate(
          widget.eventId,
          original.id,
          OrganizerUpdateParticipantRequest(
            role: roleChanged ? _role : null,
            pickupAddress: pickupChanged ? _pickup?.formattedAddress : null,
            pickupLat: pickupChanged ? _pickup?.lat : null,
            pickupLng: pickupChanged ? _pickup?.lng : null,
          ),
        );
      }
      if (_role == ParticipantRole.driver && _vehicleId != original.vehicleId) {
        await api.setVehicle(widget.eventId, original.id, _vehicleId);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.participant;
    final contactId = p.contactId;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit ${p.displayLabel}', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              DropdownButtonFormField<ParticipantRole>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Role for this event',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: ParticipantRole.passenger, child: Text('Passenger')),
                  DropdownMenuItem(value: ParticipantRole.driver, child: Text('Driver')),
                  DropdownMenuItem(
                      value: ParticipantRole.independentAttendee,
                      child: Text('Going on their own')),
                ],
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
              const SizedBox(height: 16),
              _PickupRow(pickup: _pickup, onEdit: _pickLocation),
              if (_role == ParticipantRole.driver) ...[
                const SizedBox(height: 16),
                if (contactId != null)
                  Consumer(
                    builder: (context, ref, _) {
                      final vehiclesAsync = ref.watch(contactVehiclesProvider(contactId));
                      return vehiclesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Could not load vehicles'),
                        data: (vehicles) => _VehicleRow(
                          vehicleLabel: vehicles
                              .where((v) => v.id == _vehicleId)
                              .map((v) => v.displayLabel)
                              .cast<String?>()
                              .firstOrNull,
                          onEdit: () => _pickVehicle(vehicles),
                        ),
                      );
                    },
                  )
                else
                  const Text('Vehicle selection is only available for People-added drivers.'),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupRow extends StatelessWidget {
  const _PickupRow({required this.pickup, required this.onEdit});
  final ResolvedAddress? pickup;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pickup?.formattedAddress ?? 'No pickup address',
              style: theme.textTheme.bodyLarge,
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text(pickup == null ? 'Add' : 'Change'),
          ),
        ],
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.vehicleLabel, required this.onEdit});
  final String? vehicleLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicleLabel ?? 'No vehicle selected', style: theme.textTheme.bodyLarge),
                if (vehicleLabel == null)
                  Text(
                    'Vehicle required before assignment',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text(vehicleLabel == null ? 'Choose' : 'Change'),
          ),
        ],
      ),
    );
  }
}

class _VehicleChoice {
  const _VehicleChoice(this.vehicleId);
  final String? vehicleId;
}

class _ContactVehiclePicker extends StatelessWidget {
  const _ContactVehiclePicker({
    required this.vehicles,
    required this.currentVehicleId,
  });
  final List<ContactVehicleResponse> vehicles;
  final String? currentVehicleId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose a vehicle', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (vehicles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('This contact has no vehicles on file yet.'),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: vehicles.length,
                  itemBuilder: (_, i) {
                    final v = vehicles[i];
                    final selected = v.id == currentVehicleId;
                    return ListTile(
                      leading: Icon(selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off),
                      title: Text(v.displayLabel),
                      subtitle: Text('${v.seats} seats'),
                      onTap: () =>
                          Navigator.of(context).pop(_VehicleChoice(v.id)),
                    );
                  },
                ),
              ),
            if (currentVehicleId != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Clear selection'),
                onPressed: () =>
                    Navigator.of(context).pop(const _VehicleChoice(null)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
