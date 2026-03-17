import 'package:flutter/material.dart';
import 'package:local_app_tt/services/forms_service.dart';

// ── Field type configuration with icons and colors ──────────────────────────

class _FieldTypeConfig {
  final String value;
  final String label;
  final IconData icon;
  const _FieldTypeConfig(this.value, this.label, this.icon);
}

const _fieldTypes = [
  _FieldTypeConfig('short_text', 'Short text', Icons.short_text_rounded),
  _FieldTypeConfig('long_text', 'Long text', Icons.notes_rounded),
  _FieldTypeConfig('number', 'Number', Icons.pin_rounded),
  _FieldTypeConfig('date', 'Date', Icons.calendar_today_rounded),
  _FieldTypeConfig('dropdown', 'Dropdown', Icons.arrow_drop_down_circle_rounded),
  _FieldTypeConfig('checkbox', 'Checkbox', Icons.check_box_rounded),
  _FieldTypeConfig('photo', 'Photo', Icons.photo_camera_rounded),
  _FieldTypeConfig('location', 'Location', Icons.location_on_rounded),
];

Color _fieldTypeColor(String type, ColorScheme colors) {
  switch (type) {
    case 'short_text':
      return colors.primary;
    case 'long_text':
      return colors.secondary;
    case 'number':
      return Colors.orange.shade700;
    case 'date':
      return Colors.purple.shade400;
    case 'dropdown':
      return Colors.teal.shade600;
    case 'checkbox':
      return Colors.green.shade600;
    case 'photo':
      return Colors.indigo.shade500;
    case 'location':
      return Colors.red.shade500;
    default:
      return colors.primary;
  }
}

// ── Main Screen ──────────────────────────────────────────────────────────────

class FormBuilderScreen extends StatefulWidget {
  final String initialScope;

  const FormBuilderScreen({
    super.key,
    required this.initialScope,
  });

  @override
  State<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends State<FormBuilderScreen>
    with TickerProviderStateMixin {
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
  bool _success = false;
  final List<_FieldDraftState> _fields = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // Staggered entrance animations
  late AnimationController _entranceController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _detailsFade;
  late Animation<Offset> _detailsSlide;
  late Animation<double> _fieldsFade;
  late Animation<Offset> _fieldsSlide;
  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope;
    _loadRegions();
    _setupEntranceAnimations();
  }

  void _setupEntranceAnimations() {
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _detailsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );
    _detailsSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
    ));

    _fieldsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );
    _fieldsSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));

    _buttonFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _pdfBucketController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() => _loadingRegions = true);
    final regions = await _formsService.fetchRegions();
    if (mounted) {
      setState(() {
        _regions = regions;
        _loadingRegions = false;
      });
    }
  }

  void _addField() {
    final newIndex = _fields.length;
    setState(() => _fields.add(_FieldDraftState()));
    _listKey.currentState?.insertItem(
      newIndex,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _removeField(int index) {
    final removed = _fields[index];
    setState(() => _fields.removeAt(index));
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovedField(removed, index, animation),
      duration: const Duration(milliseconds: 350),
    );
  }

  Widget _buildRemovedField(
    _FieldDraftState state,
    int index,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _FieldEditor(
          key: ValueKey('removed_$index'),
          index: index,
          state: state,
          onRemove: () {},
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    if (_fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Add at least one field.'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _submitting = true);

    final drafts = <FormFieldDraft>[];
    for (var i = 0; i < _fields.length; i++) {
      final field = _fields[i];
      if (field.label.trim().isEmpty) continue;
      drafts.add(FormFieldDraft(
        label: field.label.trim(),
        fieldType: field.type,
        isRequired: field.required,
        options: field.options,
        position: i,
      ));
    }

    try {
      await _formsService.createForm(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        scope: _scope,
        status: _status,
        regionId: _scope == 'internal' ? _regionId : null,
        pdfBucket: _pdfBucketController.text.trim().isEmpty
            ? null
            : _pdfBucketController.text.trim(),
        fields: drafts,
      );
      if (mounted) {
        setState(() {
          _success = true;
          _submitting = false;
        });
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create form: $error'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      _buildDetailsSection(theme),
                      const SizedBox(height: 20),
                      _buildFieldsSection(theme),
                      const SizedBox(height: 24),
                      _buildSubmitButton(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
        title: FadeTransition(
          opacity: _headerFade,
          child: SlideTransition(
            position: _headerSlide,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Form',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.14),
                theme.colorScheme.primaryContainer.withOpacity(0.08),
                theme.colorScheme.surface,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return FadeTransition(
      opacity: _detailsFade,
      child: SlideTransition(
        position: _detailsSlide,
        child: _SectionCard(
          title: 'Form Details',
          icon: Icons.description_rounded,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Form title',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title_rounded),
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Enter a title.'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 44),
                    child: Icon(Icons.notes_rounded),
                  ),
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Enter a description.'
                        : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SegmentedPicker(
                      label: 'Scope',
                      value: _scope,
                      options: const [
                        _PickerOption(
                            'public', 'Public', Icons.public_rounded),
                        _PickerOption(
                            'internal', 'Internal', Icons.lock_rounded),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _scope = value;
                          if (_scope == 'public') _regionId = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SegmentedPicker(
                      label: 'Status',
                      value: _status,
                      options: const [
                        _PickerOption(
                            'draft', 'Draft', Icons.edit_note_rounded),
                        _PickerOption('published', 'Published',
                            Icons.publish_rounded),
                      ],
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                child: _scope == 'internal'
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String?>(
                            value: _regionId,
                            decoration: InputDecoration(
                              labelText: 'Region (optional)',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.map_rounded),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.3),
                            ),
                            items: _loadingRegions
                                ? const []
                                : [
                                    const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('All regions')),
                                    ..._regions.map((r) =>
                                        DropdownMenuItem<String?>(
                                            value: r.id,
                                            child: Text(r.name))),
                                  ],
                            onChanged: _loadingRegions
                                ? null
                                : (value) =>
                                    setState(() => _regionId = value),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pdfBucketController,
                decoration: InputDecoration(
                  labelText: 'PDF output bucket (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.picture_as_pdf_rounded),
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldsSection(ThemeData theme) {
    return FadeTransition(
      opacity: _fieldsFade,
      child: SlideTransition(
        position: _fieldsSlide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              title: 'Form Fields',
              icon: Icons.list_alt_rounded,
              trailing: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${_fields.length} field${_fields.length == 1 ? '' : 's'}',
                  key: ValueKey(_fields.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              initialItemCount: _fields.length,
              itemBuilder: (context, index, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.35, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: _FieldEditor(
                      key: ValueKey(index),
                      index: index,
                      state: _fields[index],
                      onRemove: () => _removeField(index),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _AddFieldButton(onPressed: _addField),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return FadeTransition(
      opacity: _buttonFade,
      child: SlideTransition(
        position: _buttonSlide,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: _success
              ? _SuccessButton(key: const ValueKey('success'))
              : _SaveButton(
                  key: const ValueKey('save'),
                  submitting: _submitting,
                  onPressed: _submit,
                ),
        ),
      ),
    );
  }
}

// ── Segmented Picker ─────────────────────────────────────────────────────────

class _PickerOption {
  final String value;
  final String label;
  final IconData icon;
  const _PickerOption(this.value, this.label, this.icon);
}

class _SegmentedPicker extends StatelessWidget {
  final String label;
  final String value;
  final List<_PickerOption> options;
  final ValueChanged<String> onChanged;

  const _SegmentedPicker({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.25)),
          ),
          child: Row(
            children: options.map((opt) {
              final isSelected = opt.value == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(opt.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.all(3),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          opt.icon,
                          size: 16,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          opt.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Section Card & Header ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, icon: icon),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const _SectionHeader(
      {required this.title, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 18, color: theme.colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Add Field Button ─────────────────────────────────────────────────────────

class _AddFieldButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AddFieldButton({required this.onPressed});

  @override
  State<_AddFieldButton> createState() => _AddFieldButtonState();
}

class _AddFieldButtonState extends State<_AddFieldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.reverse();
  void _onTapUp(_) {
    _controller.forward();
    widget.onPressed();
  }

  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _controller,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            color: theme.colorScheme.primary.withOpacity(0.06),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add Field',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Save & Success Buttons ───────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool submitting;
  final VoidCallback onPressed;

  const _SaveButton(
      {super.key, required this.submitting, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: submitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: submitting
              ? const SizedBox(
                  key: ValueKey('loading'),
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  key: const ValueKey('text'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_alt_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Save Form',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SuccessButton extends StatefulWidget {
  const _SuccessButton({super.key});

  @override
  State<_SuccessButton> createState() => _SuccessButtonState();
}

class _SuccessButtonState extends State<_SuccessButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Form Saved!',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Field Draft State ────────────────────────────────────────────────────────

class _FieldDraftState {
  String label = '';
  String type = 'short_text';
  bool required = false;
  List<String> options = [];
}

// ── Field Editor ─────────────────────────────────────────────────────────────

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
    _optionsController =
        TextEditingController(text: widget.state.options.join(', '));
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
    final typeConfig =
        _fieldTypes.firstWhere((t) => t.value == widget.state.type);
    final typeColor = _fieldTypeColor(widget.state.type, theme.colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Colored header accent
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeConfig.icon, size: 16, color: typeColor),
                ),
                const SizedBox(width: 10),
                Text(
                  'Field ${widget.index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeConfig.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 20, color: theme.colorScheme.error),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.error.withOpacity(0.1),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
          ),
          // Field body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.label_outline_rounded),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  onChanged: (value) => widget.state.label = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: widget.state.type,
                  decoration: InputDecoration(
                    labelText: 'Field type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(typeConfig.icon, color: typeColor),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  items: _fieldTypes
                      .map((t) => DropdownMenuItem(
                            value: t.value,
                            child: Row(
                              children: [
                                Icon(t.icon,
                                    size: 16,
                                    color: _fieldTypeColor(
                                        t.value, theme.colorScheme)),
                                const SizedBox(width: 8),
                                Text(t.label),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => widget.state.type = value);
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: widget.state.type == 'dropdown'
                      ? Column(
                          children: [
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _optionsController,
                              decoration: InputDecoration(
                                labelText: 'Options (comma-separated)',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(
                                    Icons.format_list_bulleted_rounded),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceVariant
                                    .withOpacity(0.3),
                              ),
                              onChanged: _updateOptions,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    value: widget.state.required,
                    onChanged: (value) =>
                        setState(() => widget.state.required = value),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: const Text('Required field'),
                    subtitle: const Text('Users must fill this field'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
