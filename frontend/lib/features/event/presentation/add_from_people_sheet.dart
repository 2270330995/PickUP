import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../participant/data/participant_api.dart';
import '../../participant/data/participant_dtos.dart';
import '../../people/data/contact_api.dart';
import '../../people/data/contact_dtos.dart';

/// Organizer-only bottom sheet to add one or more Contacts from the People
/// roster to an event. Selected contacts are added atomically via the bulk
/// `from-contacts` endpoint. Returns true if any contacts were added.
Future<bool?> showAddFromPeopleSheet(
  BuildContext context, {
  required String eventId,
  required Set<String> alreadyActiveContactIds,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _AddFromPeopleSheet(
      eventId: eventId,
      alreadyActiveContactIds: alreadyActiveContactIds,
    ),
  );
}

class _Selection {
  _Selection({required this.role});
  ParticipantRole role;
  String? vehicleId;
}

class _AddFromPeopleSheet extends ConsumerStatefulWidget {
  const _AddFromPeopleSheet({
    required this.eventId,
    required this.alreadyActiveContactIds,
  });
  final String eventId;
  final Set<String> alreadyActiveContactIds;

  @override
  ConsumerState<_AddFromPeopleSheet> createState() => _AddFromPeopleSheetState();
}

class _AddFromPeopleSheetState extends ConsumerState<_AddFromPeopleSheet> {
  final Map<String, _Selection> _selected = {};
  bool _submitting = false;

  ParticipantRole _defaultRoleFor(ContactResponse contact) {
    final preferred = contact.preferredRole;
    if (preferred == null ||
        preferred == ParticipantRole.unknown ||
        preferred == ParticipantRole.organizer) {
      return ParticipantRole.passenger;
    }
    return preferred;
  }

  void _toggle(ContactResponse contact) {
    setState(() {
      if (_selected.containsKey(contact.id)) {
        _selected.remove(contact.id);
      } else {
        _selected[contact.id] = _Selection(role: _defaultRoleFor(contact));
      }
    });
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final entries = _selected.entries
          .map((e) => AddContactParticipantRequest(
                contactId: e.key,
                role: e.value.role,
                vehicleId: e.value.vehicleId,
              ))
          .toList(growable: false);
      await ref.read(participantApiProvider).addFromContacts(
            widget.eventId,
            AddContactsFromRosterRequest(entries: entries),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add from People', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Selected contacts join immediately as Ready.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: contactsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(err is ApiException ? err.message : 'Failed to load people'),
                ),
                data: (contacts) {
                  final selectable = contacts
                      .where((c) => !widget.alreadyActiveContactIds.contains(c.id))
                      .toList();
                  if (selectable.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Everyone in your People roster is already in this event.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: selectable.length,
                    itemBuilder: (_, i) {
                      final contact = selectable[i];
                      final selection = _selected[contact.id];
                      return _ContactSelectionTile(
                        contact: contact,
                        selection: selection,
                        onToggle: () => _toggle(contact),
                        onRoleChanged: (role) => setState(() {
                          selection!.role = role;
                          if (role != ParticipantRole.driver) {
                            selection.vehicleId = null;
                          }
                        }),
                        onVehicleChanged: (vehicleId) =>
                            setState(() => selection!.vehicleId = vehicleId),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submitting || _selected.isEmpty ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_selected.isEmpty
                      ? 'Select people to add'
                      : 'Add ${_selected.length} to event'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSelectionTile extends ConsumerWidget {
  const _ContactSelectionTile({
    required this.contact,
    required this.selection,
    required this.onToggle,
    required this.onRoleChanged,
    required this.onVehicleChanged,
  });

  final ContactResponse contact;
  final _Selection? selection;
  final VoidCallback onToggle;
  final ValueChanged<ParticipantRole> onRoleChanged;
  final ValueChanged<String?> onVehicleChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = selection != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              value: selected,
              onChanged: (_) => onToggle(),
              title: Text(contact.name),
              subtitle: contact.hasDefaultLocation ? Text(contact.defaultAddress!) : null,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (selected) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: DropdownButtonFormField<ParticipantRole>(
                  value: selection!.role,
                  decoration: const InputDecoration(
                    labelText: 'Role for this event',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: ParticipantRole.passenger, child: Text('Passenger')),
                    DropdownMenuItem(value: ParticipantRole.driver, child: Text('Driver')),
                    DropdownMenuItem(
                        value: ParticipantRole.independentAttendee,
                        child: Text('Going on their own')),
                  ],
                  onChanged: (v) => onRoleChanged(v ?? ParticipantRole.passenger),
                ),
              ),
              if (selection!.role == ParticipantRole.driver)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _VehicleDropdown(
                    contactId: contact.id,
                    selectedVehicleId: selection!.vehicleId,
                    onChanged: onVehicleChanged,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VehicleDropdown extends ConsumerWidget {
  const _VehicleDropdown({
    required this.contactId,
    required this.selectedVehicleId,
    required this.onChanged,
  });

  final String contactId;
  final String? selectedVehicleId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(contactVehiclesProvider(contactId));
    return vehiclesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Could not load vehicles'),
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return Text(
            'No vehicle on file — can be added without one and set later.',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        return DropdownButtonFormField<String?>(
          value: selectedVehicleId,
          decoration: const InputDecoration(
            labelText: 'Vehicle (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('No vehicle yet')),
            ...vehicles.map(
              (v) => DropdownMenuItem<String?>(value: v.id, child: Text(v.displayLabel)),
            ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}
