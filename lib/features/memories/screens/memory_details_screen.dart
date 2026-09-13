import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../models/memory_item.dart';
import '../providers/database_provider.dart';
import 'add_memory_screen.dart';

class MemoryDetailsScreen extends ConsumerStatefulWidget {
  final MemoryItem initialMemory;

  const MemoryDetailsScreen({super.key, required this.initialMemory});

  @override
  ConsumerState<MemoryDetailsScreen> createState() =>
      _MemoryDetailsScreenState();
}

class _MemoryDetailsScreenState extends ConsumerState<MemoryDetailsScreen> {
  late MemoryItem _memory;

  @override
  void initState() {
    super.initState();
    _memory = widget.initialMemory;
  }

  Future<void> _toggleFavorite() async {
    final newStatus = !_memory.isFavorite;
    setState(() {
      _memory = _memory.copyWith(isFavorite: newStatus);
    });

    final repo = ref.read(memoryRepositoryProvider);
    // toggleFavorite receives the CURRENT (old) value so it knows what to flip
    await repo.toggleFavorite(_memory.id, !newStatus);
  }

  Future<void> _editMemory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMemoryScreen(memoryToEdit: _memory),
      ),
    );

    // Refresh memory from DB
    final repo = ref.read(memoryRepositoryProvider);
    final updated = await repo.getMemoryById(_memory.id);
    if (updated != null && mounted) {
      setState(() => _memory = updated);
    }
  }

  Future<void> _deleteMemory() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Memory?',
      message:
          'Are you sure you want to delete "${_memory.title}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed && mounted) {
      final repo = ref.read(memoryRepositoryProvider);
      await repo.deleteMemory(_memory.id, photoPath: _memory.photoPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Memory deleted.'),
          backgroundColor: AppColors.darkSurfaceVariant,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = _memory.hasPhoto && File(_memory.photoPath!).existsSync();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible or Hero AppBar
          SliverAppBar(
            expandedHeight: hasPhoto ? 300 : 160,
            pinned: true,
            leading: IconButton.filledTonal(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton.filledTonal(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _memory.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(_memory.isFavorite),
                    color: _memory.isFavorite ? AppColors.favorite : null,
                  ),
                ),
                onPressed: _toggleFavorite,
                tooltip: _memory.isFavorite
                    ? 'Remove from Favorites'
                    : 'Mark as Favorite',
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.edit_rounded),
                onPressed: _editMemory,
                tooltip: 'Edit Memory',
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.favorite),
                onPressed: _deleteMemory,
                tooltip: 'Delete Memory',
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: hasPhoto
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'memory_image_${_memory.id}',
                          child: Image.file(
                            File(_memory.photoPath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withAlpha(120),
                                Colors.transparent,
                                Colors.black.withAlpha(180),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: _memory.mood.getBackgroundColor(isDark),
                      alignment: Alignment.center,
                      child: Text(
                        _memory.mood.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
            ),
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mood & Favorite Badge Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _memory.mood.getBackgroundColor(isDark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _memory.mood.color.withAlpha(100),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_memory.mood.emoji,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              _memory.mood.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _memory.mood.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_memory.isFavorite)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.favorite.withAlpha(25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.favorite.withAlpha(80),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_rounded,
                                  size: 14, color: AppColors.favorite),
                              SizedBox(width: 4),
                              Text(
                                'Cherished Favorite',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.favorite,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    _memory.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date and Time Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant.withAlpha(120),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormatter.formatFullDate(_memory.dateTime),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          DateFormatter.formatTime(_memory.dateTime),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Location
                  if (_memory.locationName != null &&
                      _memory.locationName!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _memory.locationName!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Description
                  if (_memory.description != null &&
                      _memory.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Journal Entry',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant.withAlpha(100),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF333A44)
                              : const Color(0xFFECE4DC),
                        ),
                      ),
                      child: Text(
                        _memory.description!.trim(),
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],

                  // Mini Map Preview (if coordinates available)
                  if (_memory.hasLocation) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Memory Coordinates on Map',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 200,
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                    _memory.latitude!, _memory.longitude!),
                                initialZoom: 14.0,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: AppConstants.mapTileUrl,
                                  userAgentPackageName:
                                      AppConstants.mapPackageUserAgent,
                                  tileBuilder: isDark
                                      ? (context, tileWidget, tile) =>
                                          ColorFiltered(
                                            colorFilter: const ColorFilter.matrix(
                                                AppConstants.darkMapMatrix),
                                            child: tileWidget,
                                          )
                                      : null,
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(_memory.latitude!,
                                          _memory.longitude!),
                                      width: 44,
                                      height: 44,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _memory.mood.color,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: _memory.mood.color
                                                  .withAlpha(120),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          _memory.mood.emoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_memory.latitude!.toStringAsFixed(4)}, ${_memory.longitude!.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Tags
                  if (_memory.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _memory.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF333A44)
                                  : const Color(0xFFE5DDD3),
                            ),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF7CD4BF)
                                  : AppColors.tertiary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
