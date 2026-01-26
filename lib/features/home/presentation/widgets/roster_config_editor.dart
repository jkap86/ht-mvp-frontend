import 'package:flutter/material.dart';

/// Model class to hold roster configuration
class RosterConfig {
  int qbSlots;
  int rbSlots;
  int wrSlots;
  int teSlots;
  int flexSlots;
  int kSlots;
  int defSlots;
  int bnSlots;

  RosterConfig({
    this.qbSlots = 1,
    this.rbSlots = 2,
    this.wrSlots = 2,
    this.teSlots = 1,
    this.flexSlots = 1,
    this.kSlots = 1,
    this.defSlots = 1,
    this.bnSlots = 6,
  });

  int get totalSlots =>
      qbSlots + rbSlots + wrSlots + teSlots + flexSlots + kSlots + defSlots + bnSlots;

  String get summary =>
      'QB:$qbSlots  RB:$rbSlots  WR:$wrSlots  TE:$teSlots  FLEX:$flexSlots';

  Map<String, int> toJson() {
    return {
      'QB': qbSlots,
      'RB': rbSlots,
      'WR': wrSlots,
      'TE': teSlots,
      'FLEX': flexSlots,
      'K': kSlots,
      'DEF': defSlots,
      'BN': bnSlots,
    };
  }
}

/// Collapsible editor for roster position configuration
class RosterConfigEditor extends StatelessWidget {
  final RosterConfig config;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onConfigChanged;

  const RosterConfigEditor({
    super.key,
    required this.config,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.groups, size: 18, color: colorScheme.primary),
          title: const Text('Roster Positions',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text(
            config.summary,
            style: TextStyle(
                fontSize: 11, color: colorScheme.onSurface.withAlpha(153)),
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  _PositionSlotRow(
                    label: 'QB',
                    value: config.qbSlots,
                    min: 0,
                    max: 3,
                    onChanged: (v) {
                      config.qbSlots = v;
                      onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'RB',
                    value: config.rbSlots,
                    min: 0,
                    max: 4,
                    onChanged: (v) {
                      config.rbSlots = v;
                      onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'WR',
                    value: config.wrSlots,
                    min: 0,
                    max: 4,
                    onChanged: (v) {
                      config.wrSlots = v;
                      onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'TE',
                    value: config.teSlots,
                    min: 0,
                    max: 3,
                    onChanged: (v) {
                      config.teSlots = v;
                      onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'FLEX',
                    value: config.flexSlots,
                    min: 0,
                    max: 4,
                    onChanged: (v) {
                      config.flexSlots = v;
                      onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'K',
                    value: config.kSlots,
                    min: 0,
                    max: 2,
                    onChanged: (v) {
                      config.kSlots = v;
                      onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'DEF',
                    value: config.defSlots,
                    min: 0,
                    max: 2,
                    onChanged: (v) {
                      config.defSlots = v;
                      onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'Bench',
                    value: config.bnSlots,
                    min: 0,
                    max: 15,
                    onChanged: (v) {
                      config.bnSlots = v;
                      onConfigChanged();
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total: ${config.totalSlots} roster spots',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionSlotRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _PositionSlotRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child:
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          SizedBox(
            width: 24,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
