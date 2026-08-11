import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../../participant/data/participant_dtos.dart';
import '../data/contact_api.dart';
import '../data/contact_dtos.dart';

/// The organizer's reusable People roster: drivers and passengers saved for
/// reuse across events, without requiring them to hold a PickUP account.
class PeopleListScreen extends ConsumerWidget {
  const PeopleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(contactsProvider),
        child: contactsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(err is ApiException ? err.message : 'Failed to load people'),
            ],
          ),
          data: (contacts) {
            if (contacts.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 48),
                  Center(
                    child: Text(
                      'No people yet.\nAdd drivers and passengers to reuse them across events.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _ContactCard(contact: contacts[index]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.peopleNew),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add person'),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});
  final ContactResponse contact;

  @override
  Widget build(BuildContext context) {
    final role = contact.preferredRole;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(_initial(contact.name))),
        title: Text(contact.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.phone != null && contact.phone!.isNotEmpty) Text(contact.phone!),
            if (contact.hasDefaultLocation)
              Text(
                contact.defaultAddress!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (role != null && role != ParticipantRole.unknown)
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(participantRoleLabel(role)),
              ),
            if (contact.vehicleCount > 0)
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.directions_car, size: 16),
                label: Text('${contact.vehicleCount}'),
              ),
          ],
        ),
        isThreeLine: contact.phone != null && contact.hasDefaultLocation,
        onTap: () => context.push(RoutePaths.peopleDetailFor(contact.id)),
      ),
    );
  }

  static String _initial(String name) => name.isEmpty ? '?' : name.trim()[0].toUpperCase();
}
