import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_exception.dart';
import '../data/places_api.dart';
import '../data/places_config.dart';
import '../data/resolved_address.dart';

/// Address search field backed by Google Places autocomplete.
///
/// Stores a resolved [ResolvedAddress] after the user picks a suggestion.
class AddressAutocompleteField extends FormField<ResolvedAddress> {
  AddressAutocompleteField({
    super.key,
    super.initialValue,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    required String labelText,
    String? hintText,
    String? helperText,
    ValueChanged<ResolvedAddress>? onSelected,
  }) : super(
          builder: (field) {
            return _AddressAutocompleteFieldBody(
              field: field,
              labelText: labelText,
              hintText: hintText,
              helperText: helperText,
              onSelected: onSelected,
            );
          },
        );
}

class _AddressAutocompleteFieldBody extends ConsumerStatefulWidget {
  const _AddressAutocompleteFieldBody({
    required this.field,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.onSelected,
  });

  final FormFieldState<ResolvedAddress> field;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final ValueChanged<ResolvedAddress>? onSelected;

  @override
  ConsumerState<_AddressAutocompleteFieldBody> createState() =>
      _AddressAutocompleteFieldBodyState();
}

class _AddressAutocompleteFieldBodyState extends ConsumerState<_AddressAutocompleteFieldBody> {
  final _textCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _uuid = const Uuid();
  Timer? _debounce;
  String _sessionToken = '';
  List<PlaceSuggestion> _suggestions = const [];
  bool _loading = false;
  bool _resolving = false;
  String? _searchError;
  String? _manualError;
  bool _ignoreTextChanges = false;

  bool get _manualMode => !isGooglePlacesConfigured;

  @override
  void initState() {
    super.initState();
    _sessionToken = _uuid.v4();
    final initial = widget.field.value;
    if (initial != null) {
      _ignoreTextChanges = true;
      _textCtrl.text = initial.formattedAddress;
      if (_manualMode) {
        _latCtrl.text = initial.lat.toString();
        _lngCtrl.text = initial.lng.toString();
      }
      _ignoreTextChanges = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _applyResolved(ResolvedAddress resolved) {
    _ignoreTextChanges = true;
    _textCtrl.text = resolved.formattedAddress;
    _ignoreTextChanges = false;
    widget.field.didChange(resolved);
    widget.field.validate();
    widget.onSelected?.call(resolved);
  }

  void _syncManualLocation() {
    final address = _textCtrl.text.trim();
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());

    if (address.isEmpty && _latCtrl.text.trim().isEmpty && _lngCtrl.text.trim().isEmpty) {
      setState(() => _manualError = null);
      widget.field.didChange(null);
      widget.field.validate();
      return;
    }

    if (address.isEmpty || lat == null || lng == null) {
      setState(() => _manualError = 'Enter address, latitude, and longitude');
      widget.field.didChange(null);
      widget.field.validate();
      return;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      setState(() => _manualError = 'Latitude must be -90..90 and longitude -180..180');
      widget.field.didChange(null);
      widget.field.validate();
      return;
    }

    setState(() => _manualError = null);
    _applyResolved(ResolvedAddress(formattedAddress: address, lat: lat, lng: lng));
  }

  void _onTextChanged(String value) {
    if (_ignoreTextChanges) return;

    if (_manualMode) {
      _syncManualLocation();
      return;
    }

    final current = widget.field.value;
    if (current != null && value.trim() == current.formattedAddress.trim()) {
      return;
    }

    widget.field.didChange(null);
    widget.field.validate();

    _debounce?.cancel();
    if (!isGooglePlacesConfigured) return;
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = const [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String input) async {
    setState(() {
      _loading = true;
      _searchError = null;
    });
    try {
      final results = await ref.read(placesApiProvider).autocomplete(
            input: input,
            sessionToken: _sessionToken,
          );
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _searchError = 'Address search failed';
        _suggestions = const [];
      });
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _resolving = true;
      _suggestions = const [];
      _searchError = null;
    });
    try {
      final resolved = await ref.read(placesApiProvider).resolveSuggestion(
            suggestion: suggestion,
            sessionToken: _sessionToken,
          );
      if (!mounted) return;
      _applyResolved(resolved);
      setState(() {
        _resolving = false;
        _sessionToken = _uuid.v4();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _searchError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _searchError = 'Could not resolve selected address';
      });
    }
  }

  String? get _displayError {
    if (_manualError != null) return _manualError;
    if (_searchError != null) return _searchError;
    return widget.field.errorText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _textCtrl,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            helperText: _manualMode
                ? 'Places search unavailable — enter address and coordinates manually'
                : widget.helperText,
            border: const OutlineInputBorder(),
            suffixIcon: _manualMode
                ? const Icon(Icons.edit_location_alt_outlined)
                : _loading || _resolving
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search),
            errorText: _displayError,
          ),
          textCapitalization: TextCapitalization.sentences,
          onChanged: _onTextChanged,
        ),
        if (_manualMode) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: 'e.g. 37.7759',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  onChanged: (_) => _syncManualLocation(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lngCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: 'e.g. -122.4194',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  onChanged: (_) => _syncManualLocation(),
                ),
              ),
            ],
          ),
        ],
        if (kDebugMode && widget.field.value != null && !_manualMode) ...[
          const SizedBox(height: 4),
          Text(
            'Debug: ${widget.field.value!.lat.toStringAsFixed(5)}, '
            '${widget.field.value!.lng.toStringAsFixed(5)}',
            style: theme.textTheme.labelSmall,
          ),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(item.label),
                  onTap: _resolving ? null : () => _selectSuggestion(item),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
