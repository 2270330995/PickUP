import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../../dashboard/data/dashboard_api.dart';
import '../../location/data/resolved_address.dart';
import '../../location/presentation/address_autocomplete_field.dart';
import '../data/event_api.dart';
import '../data/event_dtos.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ResolvedAddress? _destination;
  DateTime? _eventDateTime;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDateTime ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _eventDateTime ?? now.add(const Duration(hours: 1))),
    );
    if (time == null) return;
    setState(() {
      _eventDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an event date and time')),
      );
      return;
    }
    final destination = _destination;
    if (destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a destination from the suggestions')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final created = await ref.read(eventApiProvider).create(CreateEventRequest(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            destinationAddress: destination.formattedAddress,
            destinationLat: destination.lat,
            destinationLng: destination.lng,
            eventTime: _eventDateTime!,
          ));
      ref.invalidate(myEventsProvider);
      ref.invalidate(organizerDashboardProvider);
      if (!mounted) return;
      context.go(RoutePaths.organizer);
      context.push(RoutePaths.eventDetailFor(created.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New event')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                AddressAutocompleteField(
                  initialValue: _destination,
                  labelText: 'Destination address',
                  helperText: 'Start typing, then pick a suggestion',
                  onSelected: (value) => setState(() => _destination = value),
                  validator: (value) =>
                      value == null ? 'Select a destination from suggestions' : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDateTime,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _eventDateTime == null
                        ? 'Pick event date and time'
                        : _eventDateTime!.toLocal().toString(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create event'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
