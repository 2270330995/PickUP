import 'package:flutter/material.dart';

import '../data/resolved_address.dart';
import 'address_autocomplete_field.dart';

/// Bottom sheet for selecting a location via address autocomplete.
Future<ResolvedAddress?> showLocationPickerSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String fieldLabel,
  String? currentAddress,
  double? currentLat,
  double? currentLng,
  String confirmLabel = 'Save location',
}) async {
  return showModalBottomSheet<ResolvedAddress>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _LocationPickerSheet(
      title: title,
      subtitle: subtitle,
      fieldLabel: fieldLabel,
      currentAddress: currentAddress,
      currentLat: currentLat,
      currentLng: currentLng,
      confirmLabel: confirmLabel,
    ),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({
    required this.title,
    required this.subtitle,
    required this.fieldLabel,
    this.currentAddress,
    this.currentLat,
    this.currentLng,
    required this.confirmLabel,
  });

  final String title;
  final String subtitle;
  final String fieldLabel;
  final String? currentAddress;
  final double? currentLat;
  final double? currentLng;
  final String confirmLabel;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _addressFieldKey = GlobalKey<FormFieldState<ResolvedAddress>>();
  ResolvedAddress? _selected;

  @override
  void initState() {
    super.initState();
    final address = widget.currentAddress;
    final lat = widget.currentLat;
    final lng = widget.currentLng;
    if (address != null &&
        address.isNotEmpty &&
        lat != null &&
        lng != null) {
      _selected = ResolvedAddress(
        formattedAddress: address,
        lat: lat,
        lng: lng,
      );
    }
  }

  void _save() {
    final fromField = _addressFieldKey.currentState?.value;
    final value = fromField ?? _selected;
    if (value == null) {
      _formKey.currentState?.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an address from the suggestions')),
      );
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(widget.subtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              AddressAutocompleteField(
                key: _addressFieldKey,
                initialValue: _selected,
                labelText: widget.fieldLabel,
                helperText: 'Start typing, then pick a suggestion',
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSelected: (value) {
                  setState(() => _selected = value);
                  _formKey.currentState?.validate();
                },
                validator: (value) =>
                    value == null ? 'Select an address from suggestions' : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                child: Text(widget.confirmLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
