import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../data/vehicle_api.dart';
import '../data/vehicle_dtos.dart';

/// Handles both create and edit, switching based on whether an [existing]
/// vehicle is supplied. Keeps the surface small and matches the
/// pattern used by [CreateEventScreen].
class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.existing});

  final VehicleResponse? existing;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _seatsCtrl;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _makeCtrl = TextEditingController(text: e?.make ?? '');
    _modelCtrl = TextEditingController(text: e?.model ?? '');
    _colorCtrl = TextEditingController(text: e?.color ?? '');
    _plateCtrl = TextEditingController(text: e?.plate ?? '');
    _seatsCtrl = TextEditingController(text: e == null ? '4' : '${e.seats}');
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final api = ref.read(vehicleApiProvider);
    final seats = int.parse(_seatsCtrl.text.trim());
    final make = _makeCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final color = _colorCtrl.text.trim();
    final plate = _plateCtrl.text.trim();

    try {
      if (_isEdit) {
        await api.update(
          widget.existing!.id,
          UpdateVehicleRequest(
            make: make,
            model: model,
            color: color,
            plate: plate,
            seats: seats,
          ),
        );
      } else {
        await api.create(CreateVehicleRequest(
          make: make,
          model: model,
          color: color.isEmpty ? null : color,
          plate: plate.isEmpty ? null : plate,
          seats: seats,
        ));
      }
      ref.invalidate(myVehiclesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Vehicle updated' : 'Vehicle added')),
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit vehicle' : 'Add vehicle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _makeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Make',
                    hintText: 'e.g. Toyota',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Make is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'e.g. Corolla',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Model is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _colorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Color (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'License plate (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _seatsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total seats (including driver)',
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
      ),
    );
  }
}
