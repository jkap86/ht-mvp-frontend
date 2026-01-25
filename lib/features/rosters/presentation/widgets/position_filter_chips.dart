import 'package:flutter/material.dart';

class PositionFilterChips extends StatelessWidget {
  final String? selectedPosition;
  final ValueChanged<String?> onPositionSelected;
  final List<String> positions;

  const PositionFilterChips({
    super.key,
    required this.selectedPosition,
    required this.onPositionSelected,
    this.positions = const ['QB', 'RB', 'WR', 'TE', 'K', 'DEF'],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedPosition == null,
              onSelected: (_) => onPositionSelected(null),
            ),
          ),
          ...positions.map((pos) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(pos),
                selected: selectedPosition == pos,
                onSelected: (_) {
                  onPositionSelected(selectedPosition == pos ? null : pos);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
