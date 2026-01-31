import 'package:flutter/material.dart';

/// Model class to hold roster configuration
class RosterConfig {
  // Offense
  int qbSlots;
  int rbSlots;
  int wrSlots;
  int teSlots;
  // Flex
  int flexSlots;
  int superFlexSlots;
  int recFlexSlots;
  // Special Teams
  int kSlots;
  int defSlots;
  // IDP
  int dlSlots;
  int lbSlots;
  int dbSlots;
  int idpFlexSlots;
  // Reserve
  int bnSlots;
  int irSlots;
  int taxiSlots;

  RosterConfig({
    this.qbSlots = 1,
    this.rbSlots = 2,
    this.wrSlots = 2,
    this.teSlots = 1,
    this.flexSlots = 1,
    this.superFlexSlots = 0,
    this.recFlexSlots = 0,
    this.kSlots = 1,
    this.defSlots = 1,
    this.dlSlots = 0,
    this.lbSlots = 0,
    this.dbSlots = 0,
    this.idpFlexSlots = 0,
    this.bnSlots = 6,
    this.irSlots = 0,
    this.taxiSlots = 0,
  });

  int get totalSlots =>
      qbSlots + rbSlots + wrSlots + teSlots +
      flexSlots + superFlexSlots + recFlexSlots +
      kSlots + defSlots +
      dlSlots + lbSlots + dbSlots + idpFlexSlots +
      bnSlots + irSlots + taxiSlots;

  int get starterSlots =>
      qbSlots + rbSlots + wrSlots + teSlots +
      flexSlots + superFlexSlots + recFlexSlots +
      kSlots + defSlots +
      dlSlots + lbSlots + dbSlots + idpFlexSlots;

  String get summary {
    final parts = <String>[];
    if (qbSlots > 0) parts.add('QB:$qbSlots');
    if (rbSlots > 0) parts.add('RB:$rbSlots');
    if (wrSlots > 0) parts.add('WR:$wrSlots');
    if (teSlots > 0) parts.add('TE:$teSlots');
    if (flexSlots > 0) parts.add('FLX:$flexSlots');
    if (superFlexSlots > 0) parts.add('SF:$superFlexSlots');
    return parts.join('  ');
  }

  Map<String, int> toJson() {
    return {
      'QB': qbSlots,
      'RB': rbSlots,
      'WR': wrSlots,
      'TE': teSlots,
      'FLEX': flexSlots,
      'SUPER_FLEX': superFlexSlots,
      'REC_FLEX': recFlexSlots,
      'K': kSlots,
      'DEF': defSlots,
      'DL': dlSlots,
      'LB': lbSlots,
      'DB': dbSlots,
      'IDP_FLEX': idpFlexSlots,
      'BN': bnSlots,
      'IR': irSlots,
      'TAXI': taxiSlots,
    };
  }
}

/// Collapsible editor for roster position configuration
class RosterConfigEditor extends StatefulWidget {
  final RosterConfig config;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onConfigChanged;
  final String leagueMode; // 'redraft' or 'dynasty'

  const RosterConfigEditor({
    super.key,
    required this.config,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onConfigChanged,
    this.leagueMode = 'redraft',
  });

  @override
  State<RosterConfigEditor> createState() => _RosterConfigEditorState();
}

class _RosterConfigEditorState extends State<RosterConfigEditor> {
  bool _showIDP = false;
  bool _showReserve = false;

  @override
  void initState() {
    super.initState();
    // Auto-expand sections if they have values
    _showIDP = widget.config.dlSlots > 0 ||
        widget.config.lbSlots > 0 ||
        widget.config.dbSlots > 0 ||
        widget.config.idpFlexSlots > 0;
    _showReserve = widget.config.irSlots > 0 || widget.config.taxiSlots > 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDynasty = widget.leagueMode == 'dynasty';

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
            widget.config.summary,
            style: TextStyle(
                fontSize: 11, color: colorScheme.onSurface.withAlpha(153)),
          ),
          initiallyExpanded: widget.isExpanded,
          onExpansionChanged: widget.onExpansionChanged,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // OFFENSE SECTION
                  _SectionHeader(label: 'Offense'),
                  _PositionSlotRow(
                    label: 'QB',
                    value: widget.config.qbSlots,
                    min: 0,
                    max: 3,
                    onChanged: (v) {
                      widget.config.qbSlots = v;
                      widget.onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'RB',
                    value: widget.config.rbSlots,
                    min: 0,
                    max: 4,
                    onChanged: (v) {
                      widget.config.rbSlots = v;
                      widget.onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'WR',
                    value: widget.config.wrSlots,
                    min: 0,
                    max: 4,
                    onChanged: (v) {
                      widget.config.wrSlots = v;
                      widget.onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'TE',
                    value: widget.config.teSlots,
                    min: 0,
                    max: 3,
                    onChanged: (v) {
                      widget.config.teSlots = v;
                      widget.onConfigChanged();
                    },
                  ),

                  const SizedBox(height: 8),

                  // FLEX SECTION
                  _SectionHeader(label: 'Flex'),
                  _PositionSlotRow(
                    label: 'FLEX',
                    subtitle: 'RB/WR/TE',
                    value: widget.config.flexSlots,
                    min: 0,
                    max: 4,
                    onChanged: (v) {
                      widget.config.flexSlots = v;
                      widget.onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'SUPER_FLEX',
                    subtitle: 'QB/RB/WR/TE',
                    value: widget.config.superFlexSlots,
                    min: 0,
                    max: 2,
                    onChanged: (v) {
                      widget.config.superFlexSlots = v;
                      widget.onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'REC_FLEX',
                    subtitle: 'WR/TE',
                    value: widget.config.recFlexSlots,
                    min: 0,
                    max: 2,
                    onChanged: (v) {
                      widget.config.recFlexSlots = v;
                      widget.onConfigChanged();
                    },
                  ),

                  const SizedBox(height: 8),

                  // SPECIAL TEAMS SECTION
                  _SectionHeader(label: 'Special Teams'),
                  _PositionSlotRow(
                    label: 'K',
                    value: widget.config.kSlots,
                    min: 0,
                    max: 2,
                    onChanged: (v) {
                      widget.config.kSlots = v;
                      widget.onConfigChanged();
                    },
                  ),
                  _PositionSlotRow(
                    label: 'DEF',
                    value: widget.config.defSlots,
                    min: 0,
                    max: 2,
                    onChanged: (v) {
                      widget.config.defSlots = v;
                      widget.onConfigChanged();
                    },
                  ),

                  const SizedBox(height: 8),

                  // IDP SECTION (collapsible)
                  _CollapsibleSection(
                    label: 'IDP (Individual Defensive Players)',
                    isExpanded: _showIDP,
                    onToggle: () => setState(() => _showIDP = !_showIDP),
                    children: [
                      _PositionSlotRow(
                        label: 'DL',
                        subtitle: 'Defensive Line',
                        value: widget.config.dlSlots,
                        min: 0,
                        max: 4,
                        onChanged: (v) {
                          widget.config.dlSlots = v;
                          widget.onConfigChanged();
                        },
                      ),
                      _PositionSlotRow(
                        label: 'LB',
                        subtitle: 'Linebacker',
                        value: widget.config.lbSlots,
                        min: 0,
                        max: 4,
                        onChanged: (v) {
                          widget.config.lbSlots = v;
                          widget.onConfigChanged();
                        },
                      ),
                      _PositionSlotRow(
                        label: 'DB',
                        subtitle: 'Defensive Back',
                        value: widget.config.dbSlots,
                        min: 0,
                        max: 4,
                        onChanged: (v) {
                          widget.config.dbSlots = v;
                          widget.onConfigChanged();
                        },
                      ),
                      _PositionSlotRow(
                        label: 'IDP_FLEX',
                        subtitle: 'DL/LB/DB',
                        value: widget.config.idpFlexSlots,
                        min: 0,
                        max: 4,
                        onChanged: (v) {
                          widget.config.idpFlexSlots = v;
                          widget.onConfigChanged();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // RESERVE SECTION (collapsible)
                  _CollapsibleSection(
                    label: 'Reserve',
                    isExpanded: _showReserve,
                    onToggle: () => setState(() => _showReserve = !_showReserve),
                    children: [
                      _PositionSlotRow(
                        label: 'Bench',
                        value: widget.config.bnSlots,
                        min: 0,
                        max: 15,
                        onChanged: (v) {
                          widget.config.bnSlots = v;
                          widget.onConfigChanged();
                        },
                      ),
                      _PositionSlotRow(
                        label: 'IR',
                        subtitle: 'Injured Reserve',
                        value: widget.config.irSlots,
                        min: 0,
                        max: 4,
                        onChanged: (v) {
                          widget.config.irSlots = v;
                          widget.onConfigChanged();
                        },
                      ),
                      if (isDynasty)
                        _PositionSlotRow(
                          label: 'TAXI',
                          subtitle: 'Taxi Squad',
                          value: widget.config.taxiSlots,
                          min: 0,
                          max: 6,
                          onChanged: (v) {
                            widget.config.taxiSlots = v;
                            widget.onConfigChanged();
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total: ${widget.config.totalSlots} roster spots (${widget.config.starterSlots} starters)',
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

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  final String label;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _CollapsibleSection({
    required this.label,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...children,
      ],
    );
  }
}

class _PositionSlotRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _PositionSlotRow({
    required this.label,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
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
