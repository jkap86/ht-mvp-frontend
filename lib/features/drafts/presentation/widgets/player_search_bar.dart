import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

class PlayerSearchBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const PlayerSearchBar({super.key, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search players...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onChanged: onSearchChanged,
      ),
    );
  }
}
