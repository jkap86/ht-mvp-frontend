import 'package:flutter/material.dart';

/// Horizontal scrollable week selector strip.
/// Replaces PopupMenuButton week selectors with a more mobile-friendly UI.
class WeekSelectorStrip extends StatefulWidget {
  final int currentWeek;
  final int totalWeeks;
  final ValueChanged<int> onWeekSelected;

  const WeekSelectorStrip({
    super.key,
    required this.currentWeek,
    required this.totalWeeks,
    required this.onWeekSelected,
  });

  @override
  State<WeekSelectorStrip> createState() => _WeekSelectorStripState();
}

class _WeekSelectorStripState extends State<WeekSelectorStrip> {
  late ScrollController _scrollController;

  // Approximate chip width + spacing for scroll offset calculation
  static const double _chipWidth = 72;
  static const double _chipSpacing = 8;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentWeek());
  }

  @override
  void didUpdateWidget(WeekSelectorStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentWeek != widget.currentWeek) {
      _scrollToCurrentWeek();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentWeek() {
    if (!_scrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset =
        (widget.currentWeek - 1) * (_chipWidth + _chipSpacing) -
            (screenWidth / 2) +
            (_chipWidth / 2) +
            16; // account for horizontal padding

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(widget.totalWeeks, (index) {
            final week = index + 1;
            final isSelected = week == widget.currentWeek;
            return Padding(
              padding: EdgeInsets.only(
                right: index < widget.totalWeeks - 1 ? _chipSpacing : 0,
              ),
              child: ChoiceChip(
                label: Text('Wk $week'),
                selected: isSelected,
                onSelected: (_) => widget.onWeekSelected(week),
              ),
            );
          }),
        ),
      ),
    );
  }
}
