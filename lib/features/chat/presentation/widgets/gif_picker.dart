import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../data/tenor_service.dart';

/// Inline GIF picker panel that sits between the message list and input bar.
/// Shows a search bar, category chips, and a 2-column grid of GIF results.
class GifPicker extends ConsumerStatefulWidget {
  final bool compact;
  final ValueChanged<String> onGifSelected;

  const GifPicker({
    super.key,
    this.compact = false,
    required this.onGifSelected,
  });

  @override
  ConsumerState<GifPicker> createState() => _GifPickerState();
}

class _GifPickerState extends ConsumerState<GifPicker> {
  final _searchController = TextEditingController();
  GifCategory _selectedCategory = GifCategory.trending;
  List<TenorGif> _gifs = [];
  bool _isLoading = false;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadGifs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGifs() async {
    final tenor = ref.read(tenorServiceProvider);
    if (!tenor.isAvailable) return;

    setState(() => _isLoading = true);

    try {
      List<TenorGif> results;
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        results = await tenor.search(_searchQuery!);
      } else if (_selectedCategory == GifCategory.trending) {
        results = await tenor.trending();
      } else {
        results = await tenor.search(_selectedCategory.query);
      }
      if (mounted) {
        setState(() {
          _gifs = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    final tenor = ref.read(tenorServiceProvider);
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      tenor.searchDebounced(_searchQuery!).then((results) {
        if (mounted) {
          setState(() {
            _gifs = results;
            _isLoading = false;
          });
        }
      });
      setState(() => _isLoading = true);
    } else {
      _loadGifs();
    }
  }

  void _onCategorySelected(GifCategory category) {
    _searchController.clear();
    _searchQuery = null;
    setState(() => _selectedCategory = category);
    _loadGifs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final height = widget.compact ? 160.0 : 280.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search GIFs...',
                  hintStyle: theme.textTheme.bodySmall,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          // Category chips
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: GifCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final category = GifCategory.values[index];
                final isSelected = _searchQuery == null &&
                    category == _selectedCategory;
                return ChoiceChip(
                  label: Text(
                    category.label,
                    style: theme.textTheme.labelSmall,
                  ),
                  selected: isSelected,
                  onSelected: (_) => _onCategorySelected(category),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          // GIF grid
          Expanded(
            child: _isLoading
                ? _buildShimmerGrid()
                : _gifs.isEmpty
                    ? Center(
                        child: Text(
                          'No GIFs found',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: _gifs.length,
                        itemBuilder: (context, index) {
                          final gif = _gifs[index];
                          return GestureDetector(
                            onTap: () => widget.onGifSelected(gif.gifUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                gif.thumbnailUrl,
                                fit: BoxFit.cover,
                                frameBuilder: (context, child, frame,
                                    wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded ||
                                      frame != null) {
                                    return child;
                                  }
                                  return _shimmerPlaceholder(colorScheme);
                                },
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color:
                                        colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 20,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Tenor attribution
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Powered by Tenor',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _shimmerPlaceholder(colorScheme),
    );
  }

  Widget _shimmerPlaceholder(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerHigh,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
