import 'package:flutter/material.dart';
import 'package:local_app_tt/services/forms_service.dart';

class FormBuilderScreen extends StatefulWidget {
  final String initialScope;

  const FormBuilderScreen({
    super.key,
    required this.initialScope,
  });

  @override
  State<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends State<FormBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final FormsService _formsService = FormsService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pdfBucketController = TextEditingController();
  String _scope = 'public';
  String _status = 'draft';
  String? _regionId;
  List<RegionOption> _regions = [];
  bool _loadingRegions = false;
  bool _submitting = false;
  final List<_FieldDraftState> _fields = [];

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope;
    _loadRegions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pdfBucketController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() {
      _loadingRegions = true;
    });
    final regions = await _formsService.fetchRegions();
    if (mounted) {
      setState(() {
        _regions = regions;
        _loadingRegions = false;
      });
    }
  }

  void _addField() {
    setState(() {
      _fields.add(_FieldDraftState());
    });
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    if (_fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one field.')),
      );
      return;
    }
    setState(() {
      _submitting = true;
    });

    final drafts = <FormFieldDraft>[];
    for (var i = 0; i < _fields.length; i++) {
      final field = _fields[i];
      if (field.label.trim().isEmpty) {
        continue;
      }
      drafts.add(
        FormFieldDraft(
          label: field.label.trim(),
          fieldType: field.type,
          isRequired: field.required,
          options: field.options,
          position: i,
        ),
      );
    }

    try {
      await _formsService.createForm(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        scope: _scope,
        status: _status,
        regionId: _scope == 'internal' ? _regionId : null,
        pdfBucket: _pdfBucketController.text.trim().isEmpty ? null : _pdfBucketController.text.trim(),
        fields: drafts,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create form: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create form'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Form details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Form title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a title.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a description.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _scope,
                decoration: const InputDecoration(
                  labelText: 'Scope',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'internal', child: Text('Internal')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _scope = value;
                    if (_scope == 'public') {
                      _regionId = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'published', child: Text('Published')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _status = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_scope == 'internal')
                DropdownButtonFormField<String?>(
                  value: _regionId,
                  decoration: const InputDecoration(
                    labelText: 'Region (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _loadingRegions
                      ? const []
                      : [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All regions'),
                          ),
                          ..._regions.map(
                            (region) => DropdownMenuItem<String?>(
                              value: region.id,
                              child: Text(region.name),
                            ),
                          ),
                        ],
                  onChanged: _loadingRegions
                      ? null
                      : (value) {
                          setState(() {
                            _regionId = value;
                          });
                        },
                ),
              if (_scope == 'internal') const SizedBox(height: 12),
              TextFormField(
                controller: _pdfBucketController,
                decoration: const InputDecoration(
                  labelText: 'PDF output bucket (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Fields',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._fields.asMap().entries.map(
                    (entry) => _FieldEditor(
                      key: ValueKey(entry.key),
                      index: entry.key,
                      state: entry.value,
                      onRemove: () => _removeField(entry.key),
                    ),
                  ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addField,
                icon: const Icon(Icons.add),
                label: const Text('Add field'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldDraftState {
  String label = '';
  String type = 'short_text';
  bool required = false;
  List<String> options = [];
}

class _FieldEditor extends StatefulWidget {
  final int index;
  final _FieldDraftState state;
  final VoidCallback onRemove;

  const _FieldEditor({
    super.key,
    required this.index,
    required this.state,
    required this.onRemove,
  });

  @override
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  late final TextEditingController _labelController;
  late final TextEditingController _optionsController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.state.label);
    _optionsController = TextEditingController(text: widget.state.options.join(', '));
  }

  @override
  void dispose() {
    _labelController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  void _updateOptions(String value) {
    widget.state.options = value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Field ${widget.index + 1}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          TextFormField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => widget.state.label = value,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: widget.state.type,
            decoration: const InputDecoration(
              labelText: 'Field type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'short_text', child: Text('Short text')),
              DropdownMenuItem(value: 'long_text', child: Text('Long text')),
              DropdownMenuItem(value: 'number', child: Text('Number')),
              DropdownMenuItem(value: 'date', child: Text('Date')),
              DropdownMenuItem(value: 'dropdown', child: Text('Dropdown')),
              DropdownMenuItem(value: 'checkbox', child: Text('Checkbox')),
              DropdownMenuItem(value: 'photo', child: Text('Photo')),
              DropdownMenuItem(value: 'location', child: Text('Location')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                widget.state.type = value;
              });
            },
          ),
          const SizedBox(height: 12),
          if (widget.state.type == 'dropdown')
            TextFormField(
              controller: _optionsController,
              decoration: const InputDecoration(
                labelText: 'Options (comma-separated)',
                border: OutlineInputBorder(),
              ),
              onChanged: _updateOptions,
            ),
          if (widget.state.type == 'dropdown') const SizedBox(height: 12),
          SwitchListTile(
            value: widget.state.required,
            onChanged: (value) {
              setState(() {
                widget.state.required = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('Required field'),
          ),
        ],
      ),
    );
  }
}
