import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_system.dart';
import '../models/system_result.dart';
import '../providers/system_providers.dart';
import '../widgets/system_photo_picker.dart';

class SystemSetupScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final HomeSystem? existingSystem;

  const SystemSetupScreen({
    super.key,
    required this.propertyId,
    this.existingSystem,
  });

  @override
  ConsumerState<SystemSetupScreen> createState() => _SystemSetupScreenState();
}

class _SystemSetupScreenState extends ConsumerState<SystemSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late SystemType _selectedType;
  late TextEditingController _nameController;
  late TextEditingController _subtypeController;
  late TextEditingController _manufacturerController;
  late TextEditingController _modelController;
  late TextEditingController _notesController;
  DateTime? _installationDate;
  SystemCondition? _selectedCondition;
  String? _photoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final system = widget.existingSystem;

    _selectedType = system?.systemType ?? SystemType.hvac;
    _nameController = TextEditingController(text: system?.name ?? '');
    _subtypeController =
        TextEditingController(text: system?.systemSubtype ?? '');
    _manufacturerController =
        TextEditingController(text: system?.manufacturer ?? '');
    _modelController = TextEditingController(text: system?.modelNumber ?? '');
    _notesController =
        TextEditingController(text: system?.conditionNotes ?? '');
    _installationDate = system?.installationDate;
    _selectedCondition = system?.condition;
    _photoUrl = system?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtypeController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSystem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit System' : 'Add System'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 16),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildSubtypeField(),
            const SizedBox(height: 16),
            _buildManufacturerField(),
            const SizedBox(height: 16),
            _buildModelField(),
            const SizedBox(height: 16),
            _buildInstallationDateField(),
            const SizedBox(height: 16),
            _buildConditionSelector(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 16),
            _buildPhotoPicker(),
            const SizedBox(height: 24),
            _buildSaveButton(isEditing),
            if (isEditing) ...[
              const SizedBox(height: 16),
              _buildDeleteButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return DropdownButtonFormField<SystemType>(
      initialValue: _selectedType,
      decoration: const InputDecoration(
        labelText: 'System Type *',
        border: OutlineInputBorder(),
      ),
      items: SystemType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(type.icon, size: 20),
              const SizedBox(width: 8),
              Text(type.displayName),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedType = value);
        }
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'System Name *',
        hintText: 'e.g., "Main HVAC Unit"',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Name is required';
        }
        if (value.trim().length < 3) {
          return 'Name must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSubtypeField() {
    return TextFormField(
      controller: _subtypeController,
      decoration: InputDecoration(
        labelText: 'Subtype',
        hintText: _getSubtypeHint(),
        border: const OutlineInputBorder(),
      ),
      maxLength: 100,
    );
  }

  String _getSubtypeHint() {
    switch (_selectedType) {
      case SystemType.hvac:
        return 'e.g., "Furnace", "AC Unit", "Heat Pump"';
      case SystemType.waterHeater:
        return 'e.g., "Tank", "Tankless", "Heat Pump"';
      case SystemType.roof:
        return 'e.g., "Asphalt Shingles", "Metal", "Tile"';
      case SystemType.electrical:
        return 'e.g., "Main Panel", "Sub Panel"';
      case SystemType.plumbing:
        return 'e.g., "Main Line", "Water Softener"';
      case SystemType.foundation:
        return 'e.g., "Slab", "Crawl Space", "Basement"';
    }
  }

  Widget _buildManufacturerField() {
    return TextFormField(
      controller: _manufacturerController,
      decoration: const InputDecoration(
        labelText: 'Manufacturer',
        hintText: 'e.g., "Carrier", "Rheem"',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildModelField() {
    return TextFormField(
      controller: _modelController,
      decoration: const InputDecoration(
        labelText: 'Model Number',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildInstallationDateField() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Installation Date'),
      subtitle: _installationDate != null
          ? Text(
              '${_installationDate!.month}/${_installationDate!.day}/${_installationDate!.year}')
          : const Text('Not set'),
      trailing: _installationDate != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _installationDate = null),
            )
          : null,
      onTap: _pickInstallationDate,
    );
  }

  Future<void> _pickInstallationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _installationDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _installationDate = date);
    }
  }

  Widget _buildConditionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Condition', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: SystemCondition.values.map((condition) {
            final isSelected = _selectedCondition == condition;
            return ChoiceChip(
              label: Text(condition.displayName),
              avatar: Icon(
                condition.icon,
                size: 16,
                color: isSelected ? Colors.white : condition.color,
              ),
              selected: isSelected,
              selectedColor: condition.color,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
              onSelected: (selected) {
                setState(() => _selectedCondition = selected ? condition : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Condition Notes',
        hintText: 'Any issues, repairs, or observations...',
        border: OutlineInputBorder(),
      ),
      maxLines: 4,
      maxLength: 2000,
    );
  }

  Widget _buildPhotoPicker() {
    return SystemPhotoPicker(
      photoUrl: _photoUrl,
      onPhotoSelected: (url) => setState(() => _photoUrl = url),
      systemId: widget.existingSystem?.id,
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveSystem,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(isEditing ? 'Update System' : 'Add System'),
    );
  }

  Widget _buildDeleteButton() {
    return OutlinedButton(
      onPressed: _isLoading ? null : _deleteSystem,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
      ),
      child: const Text('Delete System'),
    );
  }

  Future<void> _saveSystem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final service = ref.read(systemServiceProvider);
    final isEditing = widget.existingSystem != null;

    final system = HomeSystem(
      id: widget.existingSystem?.id ?? '',
      propertyId: widget.propertyId,
      name: _nameController.text.trim(),
      systemType: _selectedType,
      systemSubtype: _subtypeController.text.trim().isEmpty
          ? null
          : _subtypeController.text.trim(),
      manufacturer: _manufacturerController.text.trim().isEmpty
          ? null
          : _manufacturerController.text.trim(),
      modelNumber: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      installationDate: _installationDate,
      condition: _selectedCondition,
      conditionNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      photoUrl: _photoUrl,
      createdAt: widget.existingSystem?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = isEditing
        ? await service.updateSystem(system)
        : await service.createSystem(system);

    if (!mounted) return;

    setState(() => _isLoading = false);

    switch (result) {
      case SystemSuccess():
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'System updated successfully'
                : 'System added successfully'),
          ),
        );
        Navigator.of(context).pop();
      case SystemFailure(:final error):
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _deleteSystem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete System'),
        content: const Text(
          'Are you sure you want to delete this system? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final service = ref.read(systemServiceProvider);
    final result = await service.deleteSystem(widget.existingSystem!.id);

    if (!mounted) return;

    setState(() => _isLoading = false);

    switch (result) {
      case SystemSuccess():
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System deleted successfully')),
        );
        Navigator.of(context).pop();
      case SystemFailure(:final error):
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
    }
  }
}
