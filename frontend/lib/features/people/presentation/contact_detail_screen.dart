import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../../participant/data/participant_dtos.dart';
import '../data/contact_api.dart';
import '../data/contact_dtos.dart';
import 'contact_vehicle_form_sheet.dart';

class ContactDetailScreen extends ConsumerWidget {
  const ContactDetailScreen({super.key, required this.contactId});

  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactDetailProvider(contactId));
    return Scaffold(
      appBar: AppBar(
        title: contactAsync.maybeWhen(
          data: (c) => Text(c.name),
          orElse: () => const Text('Person'),
        ),
        actions: [
          contactAsync.maybeWhen(
            data: (contact) => IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(RoutePaths.peopleEditFor(contact.id), extra: contact),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: contactAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(err is ApiException ? err.message : 'Failed to load person'),
        ),
        data: (contact) => _ContactDetailBody(contact: contact),
      ),
    );
  }
}

class _ContactDetailBody extends ConsumerWidget {
  const _ContactDetailBody({required this.contact});
  final ContactResponse contact;

  Future<void> _confirmArchive(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive this person?'),
        content: Text(
          '${contact.name} will be hidden from your People list. This can\'t be undone from the app yet.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Archive')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(contactApiProvider).archive(contact.id);
      ref.invalidate(contactsProvider);
      if (!context.mounted) return;
      context.pop();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(contactVehiclesProvider(contact.id));
    final role = contact.preferredRole;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(contactDetailProvider(contact.id));
        ref.invalidate(contactVehiclesProvider(contact.id));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (role != null && role != ParticipantRole.unknown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Chip(label: Text('Usually: ${participantRoleLabel(role)}')),
                    ),
                  if (contact.phone != null && contact.phone!.isNotEmpty)
                    _InfoRow(icon: Icons.call_outlined, text: contact.phone!),
                  if (contact.email != null && contact.email!.isNotEmpty)
                    _InfoRow(icon: Icons.mail_outline, text: contact.email!),
                  if (contact.hasDefaultLocation)
                    _InfoRow(icon: Icons.place_outlined, text: contact.defaultAddress!),
                  if (contact.notes != null && contact.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(contact.notes!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vehicles', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => ContactVehicleFormSheet.show(context, contactId: contact.id),
                icon: const Icon(Icons.add),
                label: const Text('Add vehicle'),
              ),
            ],
          ),
          vehiclesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Could not load vehicles'),
            ),
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No vehicles yet.'),
                );
              }
              return Column(
                children: vehicles
                    .map((v) => _VehicleCard(contactId: contact.id, vehicle: v))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _confirmArchive(context, ref),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive person'),
            style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  const _VehicleCard({required this.contactId, required this.vehicle});
  final String contactId;
  final ContactVehicleResponse vehicle;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(contactApiProvider).deleteVehicle(contactId, vehicle.id);
      ref.invalidate(contactVehiclesProvider(contactId));
      ref.invalidate(contactDetailProvider(contactId));
      ref.invalidate(contactsProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_car_outlined),
        title: Text(vehicle.displayLabel),
        subtitle: Text('${vehicle.seats} seats total'),
        onTap: () => ContactVehicleFormSheet.show(context, contactId: contactId, existing: vehicle),
        trailing: IconButton(
          tooltip: 'Remove vehicle',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(context, ref),
        ),
      ),
    );
  }
}
