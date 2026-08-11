import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../location/data/resolved_address.dart';
import '../../location/presentation/address_autocomplete_field.dart';
import '../../participant/data/participant_dtos.dart';
import '../data/contact_api.dart';
import '../data/contact_dtos.dart';

/// Selectable preferred-role hints. Organizer role is never a valid Contact hint.
const _preferredRoleOptions = [
  ParticipantRole.driver,
  ParticipantRole.passenger,
  ParticipantRole.independentAttendee,
];

/// Handles both create and edit for a Contact, switching based on whether
/// an [existing] contact is supplied.
class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({super.key, this.existing});

  final ContactResponse? existing;

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _notesCtrl;
  ResolvedAddress? _defaultLocation;
  ParticipantRole? _preferredRole;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _preferredRole = e?.preferredRole;
    if (e != null && e.hasDefaultLocation && e.defaultLat != null && e.defaultLng != null) {
      _defaultLocation = ResolvedAddress(
        formattedAddress: e.defaultAddress!,
        lat: e.defaultLat!,
        lng: e.defaultLng!,
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _locationLabel {
    switch (_preferredRole) {
      case ParticipantRole.driver:
        return 'Default start location (optional)';
      case ParticipantRole.passenger:
        return 'Default pickup location (optional)';
      default:
        return 'Default location (optional)';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final api = ref.read(contactApiProvider);
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final location = _defaultLocation;

    try {
      if (_isEdit) {
        await api.update(
          widget.existing!.id,
          UpdateContactRequest(
            name: name,
            phone: phone,
            email: email,
            // Only send location when Places resolved a full triad. Sending an empty
            // address without lat/lng would clear the address but leave stale
            // coordinates and fail backend validation.
            defaultAddress: location?.formattedAddress,
            defaultLat: location?.lat,
            defaultLng: location?.lng,
            notes: notes,
            preferredRole: _preferredRole,
          ),
        );
      } else {
        await api.create(CreateContactRequest(
          name: name,
          phone: phone.isEmpty ? null : phone,
          email: email.isEmpty ? null : email,
          defaultAddress: location?.formattedAddress,
          defaultLat: location?.lat,
          defaultLng: location?.lng,
          notes: notes.isEmpty ? null : notes,
          preferredRole: _preferredRole,
        ));
      }
      ref.invalidate(contactsProvider);
      if (widget.existing != null) {
        ref.invalidate(contactDetailProvider(widget.existing!.id));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Person updated' : 'Person added')),
      );
      context.pop();
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit person' : 'Add person')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ParticipantRole?>(
                  initialValue: _preferredRole,
                  decoration: const InputDecoration(
                    labelText: 'Usually joins as (optional)',
                    helperText: 'A hint only — the role for a specific event is set there',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<ParticipantRole?>(value: null, child: Text('No preference')),
                    ..._preferredRoleOptions.map(
                      (r) => DropdownMenuItem<ParticipantRole?>(
                        value: r,
                        child: Text(participantRoleLabel(r)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _preferredRole = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                AddressAutocompleteField(
                  initialValue: _defaultLocation,
                  labelText: _locationLabel,
                  helperText: 'Pre-fills this address when added to future events',
                  onSelected: (value) => setState(() => _defaultLocation = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
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
                      : Text(_isEdit ? 'Save changes' : 'Add person'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
