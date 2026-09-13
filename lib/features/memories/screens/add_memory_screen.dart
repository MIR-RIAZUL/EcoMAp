import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/mood_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/file_helper.dart';
import '../../../core/utils/location_service.dart';
import '../models/memory_item.dart';
import '../providers/database_provider.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/mood_selector.dart';

class AddMemoryScreen extends ConsumerStatefulWidget {
  final MemoryItem? memoryToEdit;

  const AddMemoryScreen({super.key, this.memoryToEdit});

  @override
  ConsumerState<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends ConsumerState<AddMemoryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _tagInputController;

  late Mood _selectedMood;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  String? _photoPath;
  double? _latitude;
  double? _longitude;
  late List<String> _tags;
  bool _isSaving = false;
  bool _isFavorite = false;
  bool _isDetectingGps = false;

  final ImagePicker _picker = ImagePicker();

  bool get isEditMode => widget.memoryToEdit != null;

  @override
  void initState() {
    super.initState();
    final m = widget.memoryToEdit;

    _titleController = TextEditingController(text: m?.title ?? '');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _locationController = TextEditingController(text: m?.locationName ?? '');
    _tagInputController = TextEditingController();

    _selectedMood = m?.mood ?? Mood.happy;
    _selectedDate = m?.dateTime ?? DateTime.now();
    _selectedTime = m != null
        ? TimeOfDay.fromDateTime(m.dateTime)
        : TimeOfDay.now();

    _photoPath = m?.photoPath;
    _latitude = m?.latitude;
    _longitude = m?.longitude;
    _tags = m != null ? List<String>.from(m.tags) : [];
    _isFavorite = m?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final permanentPath = await FileHelper.saveImagePermanently(image.path);
        setState(() {
          _photoPath = permanentPath;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not access photos: $e'),
          backgroundColor: AppColors.favorite,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.favorite),
                title: const Text('Remove Photo', style: TextStyle(color: AppColors.favorite)),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _openMapLocationPicker() async {
    final result = await LocationPickerSheet.show(
      context,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
      initialLocationName: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
    );

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationController.text = result.locationName;
      });
    }
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetectingGps = true);
    final result = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isDetectingGps = false);

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationController.text = result.locationName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Location found: ${result.locationName}')),
            ],
          ),
          backgroundColor: AppColors.tertiary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Could not detect GPS position. Please check location permissions.'),
          backgroundColor: AppColors.favorite,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _addTag() {
    final rawTag = _tagInputController.text.trim();
    if (rawTag.isNotEmpty) {
      final clean = rawTag.replaceAll('#', '').trim();
      if (clean.isNotEmpty && !_tags.contains(clean)) {
        setState(() {
          _tags.add(clean);
          _tagInputController.clear();
        });
      }
    }
  }

  Future<void> _saveMemory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final memoryItem = MemoryItem(
      id: widget.memoryToEdit?.id ?? 0,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      photoPath: _photoPath,
      dateTime: finalDateTime,
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      mood: _selectedMood,
      tags: _tags,
      isFavorite: _isFavorite,
      createdAt: widget.memoryToEdit?.createdAt ?? DateTime.now(),
    );

    try {
      final repo = ref.read(memoryRepositoryProvider);
      if (isEditMode) {
        await repo.updateMemory(memoryItem);
      } else {
        await repo.insertMemory(memoryItem);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(isEditMode
                  ? 'Memory updated successfully!'
                  : 'Memory saved to your EchoMap!'),
            ],
          ),
          backgroundColor: AppColors.tertiary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save memory: $e'),
          backgroundColor: AppColors.favorite,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Memory' : 'Capture Memory'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? AppColors.favorite : null,
            ),
            tooltip: _isFavorite ? 'Remove Favorite' : 'Mark Favorite',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _saveMemory,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                isEditMode ? 'Update' : 'Save',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Photo Picker Card
            _buildPhotoPicker(isDark),
            const SizedBox(height: 20),

            // Title Field (Required)
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Memory Title *',
                hintText: 'e.g. First day at university',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a title for your memory';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Mood Selector
            MoodSelector(
              selectedMood: _selectedMood,
              onMoodSelected: (mood) => setState(() => _selectedMood = mood),
            ),
            const SizedBox(height: 20),

            // Date and Time Pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant.withAlpha(120),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF323843)
                              : const Color(0xFFE8E0D7),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormatter.formatFullDate(_selectedDate),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant.withAlpha(120),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF323843)
                              : const Color(0xFFE8E0D7),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Location Input + Map Picker Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location (Optional)',
                      hintText: 'e.g. United International University',
                      prefixIcon: const Icon(Icons.place_rounded),
                      suffixIcon: _locationController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _locationController.clear();
                                  _latitude = null;
                                  _longitude = null;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: _openMapLocationPicker,
                  icon: const Icon(Icons.map_rounded),
                  tooltip: 'Pick location on Map',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded,
                        size: 12, color: AppColors.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Coordinates: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Description Field (Optional, Multiline)
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText:
                    'What made this moment special? Pour your thoughts here...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),

            // Tags input section
            _buildTagsSection(isDark),
            const SizedBox(height: 24),

            // Big Save Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveMemory,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                isEditMode ? 'Update Memory' : 'Save Memory to EchoMap',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(bool isDark) {
    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();

    if (hasPhoto) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Image.file(
              File(_photoPath!),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                    onPressed: _showImageSourceDialog,
                    tooltip: 'Change Photo',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.favorite, size: 20),
                    onPressed: () => setState(() => _photoPath = null),
                    tooltip: 'Remove Photo',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant.withAlpha(140)
              : AppColors.lightSurfaceVariant.withAlpha(100),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF333A44) : const Color(0xFFDDD5CB),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add a Memory Photo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Capture from camera or pick from gallery',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.label_outline_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text(
              'Tags & Topics',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Tag input text field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagInputController,
                decoration: const InputDecoration(
                  hintText: 'Type tag and press + (e.g. University)',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addTag,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add Tag',
            ),
          ],
        ),

        // Current tags
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _tags.map((tag) {
              return Chip(
                label: Text('#$tag'),
                onDeleted: () {
                  setState(() => _tags.remove(tag));
                },
                deleteIconColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              );
            }).toList(),
          ),
        ],

        // Suggestions
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.defaultTags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final defaultTag = AppConstants.defaultTags[index];
              final isAdded = _tags.contains(defaultTag);
              if (isAdded) return const SizedBox.shrink();

              return ActionChip(
                label: Text(
                  '+ $defaultTag',
                  style: const TextStyle(fontSize: 11),
                ),
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() => _tags.add(defaultTag));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
