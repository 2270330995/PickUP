import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/contact_api.dart';
import '../data/contact_dtos.dart';

/// Bottom sheet for adding or editing a vehicle owned by a Contact.
/// Contact-scoped (see `ContactVehicleController`) — replaces the legacy
/// user-owned vehicle garage form for the organizer-first workflow.
class ContactVehicleFormSheet extends ConsumerStatefulWidget {
  const ContactVehicleFormSheet({
    super.key,
    required this.contactId,
    this.existing,
  });

  final String contactId;
  final ContactVehicleResponse? existing;

  static Future<void> show(
    BuildContext context, {
    required String contactId,
    ContactVehicleResponse? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ContactVehicleFormSheet(contactId: contactId, existing: existing),
    );
  }

  @override
  ConsumerState<ContactVehicleFormSheet> createState() => _ContactVehicleFormSheetState();
}

class _ContactVehicleFormSheetState extends ConsumerState<ContactVehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _seatsCtrl;
  late final TextEditingController _notesCtrl;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _labelCtrl = TextEditingController(text: v?.label ?? '');
    _makeCtrl = TextEditingController(text: v?.make ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _colorCtrl = TextEditingController(text: v?.color ?? '');
    _plateCtrl = TextEditingController(text: v?.plate ?? '');
    _seatsCtrl = TextEditingController(text: v == null ? '4' : '${v.seats}');
    _notesCtrl = TextEditingController(text: v?.notes ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    _seatsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final api = ref.read(contactApiProvider);
    final label = _labelCtrl.text.trim();
    final make = _makeCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final color = _colorCtrl.text.trim();
    final plate = _plateCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final seats = int.parse(_seatsCtrl.text.trim());

    try {
      if (_isEdit) {
        await api.updateVehicle(
          widget.contactId,
          widget.existing!.id,
          UpdateContactVehicleRequest(
            label: label,
            make: make,
            model: model,
            color: color,
            plate: plate,
            seats: seats,
            notes: notes,
          ),
        );
      } else {
        await api.createVehicle(
          widget.contactId,
          CreateContactVehicleRequest(
            label: label.isEmpty ? null : label,
            make: make,
            model: model,
            color: color.isEmpty ? null : color,
            plate: plate.isEmpty ? null : plate,
            seats: seats,
            notes: notes.isEmpty ? null : notes,
          ),
        );
      }
      ref.invalidate(contactVehiclesProvider(widget.contactId));
      ref.invalidate(contactDetailProvider(widget.contactId));
      ref.invalidate(contactsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEdit ? 'Edit vehicle' : 'Add vehicle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label (optional)',
                  hintText: "e.g. Craig's Honda",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _makeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Make',
                  hintText: 'e.g. Toyota',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Make is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'e.g. Corolla',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Model is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _colorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Color (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _plateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Plate (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seatsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total seats',
                  helperText: 'Including the driver',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v.trim());
                  if (n == null) return 'Not a number';
                  if (n < 1 || n > 15) return 'Must be between 1 and 15';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
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
                    : Text(_isEdit ? 'Save changes' : 'Add vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
