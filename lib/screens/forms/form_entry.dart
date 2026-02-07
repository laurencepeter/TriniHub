import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_app_tt/services/forms_service.dart';

class FormEntryScreen extends StatefulWidget {
  final FormTemplate form;

  const FormEntryScreen({
    super.key,
    required this.form,
  });

  @override
  State<FormEntryScreen> createState() => _FormEntryScreenState();
}

class _FormEntryScreenState extends State<FormEntryScreen> {
  final FormsService _formsService = FormsService();
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _responses = {};
  final Map<String, XFile> _photoFiles = {};
  bool _loading = true;
  bool _submitting = false;
  List<FormFieldTemplate> _fields = [];
  double? _latitude;
  double? _longitude;
  String? _locationLabel;
  List<NearbySubmission> _nearby = [];

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFields() async {
    final fields = await _formsService.fetchFields(widget.form.id);
    if (!mounted) return;
    setState(() {
      _fields = fields;
      _loading = false;
    });
  }

  Future<void> _captureLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Location services are disabled.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnack('Location permission denied.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnack('Location permissions are permanently denied.');
      return;
    }
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationLabel = 'Lat ${position.latitude.toStringAsFixed(4)}, Lng ${position.longitude.toStringAsFixed(4)}';
      for (final field in _fields.where((item) => item.fieldType == 'location')) {
        _responses[field.id] = _locationLabel;
      }
    });
    await _loadNearby();
  }

  Future<void> _loadNearby() async {
    if (_latitude == null || _longitude == null) {
      return;
    }
    final results = await _formsService.fetchNearbySubmissions(
      formId: widget.form.id,
      latitude: _latitude!,
      longitude: _longitude!,
    );
    if (!mounted) return;
    setState(() {
      _nearby = results;
    });
  }

  TextEditingController _controllerFor(FormFieldTemplate field) {
    return _controllers.putIfAbsent(field.id, () => TextEditingController());
  }

  Future<void> _capturePhoto(FormFieldTemplate field) async {
    final file = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _photoFiles[field.id] = file;
    });
  }

  bool _validateRequired() {
    for (final field in _fields) {
      if (!field.isRequired) continue;
      if (field.fieldType == 'photo') {
        if (!_photoFiles.containsKey(field.id)) {
          _showSnack('Capture a photo for ${field.label}.');
          return false;
        }
        continue;
      }
      if (field.fieldType == 'location') {
        if (_latitude == null || _longitude == null) {
          _showSnack('Capture a location for ${field.label}.');
          return false;
        }
        continue;
      }
      final value = _responses[field.id];
      if (value == null || (value is String && value.trim().isEmpty)) {
        _showSnack('Complete ${field.label}.');
        return false;
      }
    }
    return true;
  }

  String _buildSummary() {
    final textEntries = <String>[];
    for (final field in _fields) {
      if (field.fieldType == 'short_text' || field.fieldType == 'long_text') {
        final value = _responses[field.id];
        if (value != null && value.toString().trim().isNotEmpty) {
          textEntries.add(value.toString());
        }
      }
    }
    if (textEntries.isEmpty) {
      return 'Submission for ${widget.form.title}';
    }
    return textEntries.take(2).join(' · ');
  }

  Future<void> _submit() async {
    if (!_validateRequired()) {
      return;
    }
    setState(() {
      _submitting = true;
    });

    try {
      final summary = _buildSummary();
      final responsePayload = Map<String, dynamic>.from(_responses);
      if (_locationLabel != null) {
        responsePayload['location_label'] = _locationLabel;
      }
      final submissionId = await _formsService.createSubmission(
        formId: widget.form.id,
        responses: responsePayload,
        summary: summary,
        latitude: _latitude,
        longitude: _longitude,
        locationLabel: _locationLabel,
        regionId: widget.form.regionId,
      );

      if (_photoFiles.isNotEmpty) {
        for (final entry in _photoFiles.entries) {
          final bytes = await entry.value.readAsBytes();
          final filename = entry.value.name;
          final url = await _formsService.uploadPhoto(
            folder: submissionId,
            filename: filename,
            bytes: bytes,
          );
          responsePayload[entry.key] = url;
        }
        await _formsService.updateSubmissionResponses(
          submissionId: submissionId,
          responses: responsePayload,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission sent!')),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack('Failed to submit: $error');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.form.title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.form.description,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 16),
            ..._fields.map(_buildField),
            const SizedBox(height: 20),
            if (_nearby.isNotEmpty) _NearbyPanel(nearby: _nearby),
            if (_nearby.isNotEmpty) const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(FormFieldTemplate field) {
    final theme = Theme.of(context);
    switch (field.fieldType) {
      case 'short_text':
        return _TextFieldBlock(
          label: field.label,
          requiredField: field.isRequired,
          controller: _controllerFor(field),
          onChanged: (value) => _responses[field.id] = value,
        );
      case 'long_text':
        return _TextFieldBlock(
          label: field.label,
          requiredField: field.isRequired,
          controller: _controllerFor(field),
          maxLines: 4,
          onChanged: (value) => _responses[field.id] = value,
        );
      case 'number':
        return _TextFieldBlock(
          label: field.label,
          requiredField: field.isRequired,
          controller: _controllerFor(field),
          keyboardType: TextInputType.number,
          onChanged: (value) => _responses[field.id] = value,
        );
      case 'date':
        return _DatePickerField(
          label: field.label,
          requiredField: field.isRequired,
          onSelected: (value) => _responses[field.id] = value,
        );
      case 'dropdown':
        return _DropdownField(
          label: field.label,
          requiredField: field.isRequired,
          options: field.options,
          onChanged: (value) => _responses[field.id] = value,
        );
      case 'checkbox':
        final current = _responses[field.id] as bool? ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: current,
            title: Text(field.label),
            subtitle: field.isRequired ? const Text('Required') : null,
            onChanged: (value) {
              setState(() {
                _responses[field.id] = value ?? false;
              });
            },
          ),
        );
      case 'photo':
        final file = _photoFiles[field.id];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (field.isRequired)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Required', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                ),
              const SizedBox(height: 8),
              if (file != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(file.path),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(Icons.camera_alt_outlined, size: 36)),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _capturePhoto(field),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(file == null ? 'Capture photo' : 'Retake photo'),
              ),
            ],
          ),
        );
      case 'location':
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (field.isRequired)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Required', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                ),
              const SizedBox(height: 8),
              Text(
                _locationLabel ?? 'No location captured yet.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _captureLocation,
                icon: const Icon(Icons.my_location),
                label: Text(_locationLabel == null ? 'Capture location' : 'Update location'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _TextFieldBlock extends StatelessWidget {
  final String label;
  final bool requiredField;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _TextFieldBlock({
    required this.label,
    required this.requiredField,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: requiredField ? 'Required' : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _DatePickerField extends StatefulWidget {
  final String label;
  final bool requiredField;
  final ValueChanged<String> onSelected;

  const _DatePickerField({
    required this.label,
    required this.requiredField,
    required this.onSelected,
  });

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  DateTime? _selected;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _selected = picked;
    });
    widget.onSelected(picked.toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    final display = _selected == null
        ? 'Pick a date'
        : '${_selected!.year}-${_selected!.month.toString().padLeft(2, '0')}-${_selected!.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: _pickDate,
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text('${widget.label} · $display${widget.requiredField ? ' (required)' : ''}'),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final bool requiredField;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.requiredField,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          helperText: requiredField ? 'Required' : null,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(
                value: option,
                child: Text(option),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _NearbyPanel extends StatelessWidget {
  final List<NearbySubmission> nearby;

  const _NearbyPanel({
    required this.nearby,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nearby similar submissions',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...nearby.map(
            (submission) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.place_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${submission.summary ?? 'Submission'} · ${submission.distanceKm.toStringAsFixed(2)} km away',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  _StatusPill(status: submission.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
