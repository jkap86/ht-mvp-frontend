import 'package:flutter/material.dart';

/// Model class to hold all scoring settings
class ScoringSettings {
  // Passing
  int passingTdPoints;
  int passingYardsPerPoint;
  int interceptionPoints;

  // Rushing
  int rushingTdPoints;
  int rushingYardsPerPoint;

  // Receiving
  double pprValue;
  int receivingTdPoints;
  int receivingYardsPerPoint;
  double tePremium;

  // Bonuses
  int bonus100YardRush;
  int bonus100YardRec;
  int bonus300YardPass;

  // Misc
  int fumbleLostPoints;
  int twoPtConversion;

  ScoringSettings({
    this.passingTdPoints = 4,
    this.passingYardsPerPoint = 25,
    this.interceptionPoints = -1,
    this.rushingTdPoints = 6,
    this.rushingYardsPerPoint = 10,
    this.pprValue = 1.0,
    this.receivingTdPoints = 6,
    this.receivingYardsPerPoint = 10,
    this.tePremium = 0.0,
    this.bonus100YardRush = 0,
    this.bonus100YardRec = 0,
    this.bonus300YardPass = 0,
    this.fumbleLostPoints = -2,
    this.twoPtConversion = 2,
  });

  Map<String, dynamic> toJson() {
    return {
      'pass_td': passingTdPoints,
      'pass_yd': 1.0 / passingYardsPerPoint,
      'pass_int': interceptionPoints,
      'rush_td': rushingTdPoints,
      'rush_yd': 1.0 / rushingYardsPerPoint,
      'rec': pprValue,
      'rec_td': receivingTdPoints,
      'rec_yd': 1.0 / receivingYardsPerPoint,
      'te_premium': tePremium,
      'bonus_rush_yd_100': bonus100YardRush,
      'bonus_rec_yd_100': bonus100YardRec,
      'bonus_pass_yd_300': bonus300YardPass,
      'fum_lost': fumbleLostPoints,
      'two_pt': twoPtConversion,
    };
  }

  String get summary =>
      'PPR: $pprValue  Pass TD: $passingTdPoints  Rush TD: $rushingTdPoints';
}

/// Collapsible editor for scoring settings
class ScoringSettingsEditor extends StatelessWidget {
  final ScoringSettings settings;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onSettingsChanged;

  const ScoringSettingsEditor({
    super.key,
    required this.settings,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onSettingsChanged,
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
          leading: Icon(Icons.scoreboard_outlined,
              size: 18, color: colorScheme.primary),
          title: const Text('Scoring Settings',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text(
            settings.summary,
            style: TextStyle(
                fontSize: 11, color: colorScheme.onSurface.withAlpha(153)),
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(context, 'Passing', [
                    _ScoringInputData(
                      label: 'Passing TD',
                      value: settings.passingTdPoints,
                      onChanged: (v) {
                        settings.passingTdPoints = v.toInt();
                        onSettingsChanged();
                      },
                    ),
                    _ScoringInputData(
                      label: 'Yards per Point',
                      value: settings.passingYardsPerPoint,
                      onChanged: (v) {
                        settings.passingYardsPerPoint = v.toInt();
                        onSettingsChanged();
                      },
                    ),
                    _ScoringInputData(
                      label: 'Interception',
                      value: settings.interceptionPoints,
                      onChanged: (v) {
                        settings.interceptionPoints = v.toInt();
                        onSettingsChanged();
                      },
                      allowNegative: true,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection(context, 'Rushing', [
                    _ScoringInputData(
                      label: 'Rushing TD',
                      value: settings.rushingTdPoints,
                      onChanged: (v) {
                        settings.rushingTdPoints = v.toInt();
                        onSettingsChanged();
                      },
                    ),
                    _ScoringInputData(
                      label: 'Yards per Point',
                      value: settings.rushingYardsPerPoint,
                      onChanged: (v) {
                        settings.rushingYardsPerPoint = v.toInt();
                        onSettingsChanged();
                      },
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection(context, 'Receiving', [
                    _ScoringInputData(
                      label: 'PPR (per reception)',
                      value: settings.pprValue,
                      onChanged: (v) {
                        settings.pprValue = v.toDouble();
                        onSettingsChanged();
                      },
                      allowDecimal: true,
                    ),
                    _ScoringInputData(
                      label: 'Receiving TD',
                      value: settings.receivingTdPoints,
                      onChanged: (v) {
                        settings.receivingTdPoints = v.toInt();
                        onSettingsChanged();
                      },
                    ),
                    _ScoringInputData(
                      label: 'Yards per Point',
                      value: settings.receivingYardsPerPoint,
                      onChanged: (v) {
                        settings.receivingYardsPerPoint = v.toInt();
                        onSettingsChanged();
                      },
                    ),
                    _ScoringInputData(
                      label: 'TE Premium',
                      value: settings.tePremium,
                      onChanged: (v) {
                        settings.tePremium = v.toDouble();
                        onSettingsChanged();
                      },
                      allowDecimal: true,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection(context, 'Bonuses', [
                    _ScoringInputData(
                      label: '100+ Rush Yards',
                      value: settings.bonus100YardRush,
                      onChanged: (v) {
                        settings.bonus100YardRush = v.toInt();
                        onSettingsChanged();
                      },
                    ),
                    _ScoringInputData(
                      label: '100+ Rec Yards',
                      value: settings.bonus100YardRec,
                      onChanged: (v) {
                        settings.bonus100YardRec = v.toInt();
                        onSettingsChanged();
                      },
                    ),
                    _ScoringInputData(
                      label: '300+ Pass Yards',
                      value: settings.bonus300YardPass,
                      onChanged: (v) {
                        settings.bonus300YardPass = v.toInt();
                        onSettingsChanged();
                      },
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection(context, 'Miscellaneous', [
                    _ScoringInputData(
                      label: 'Fumble Lost',
                      value: settings.fumbleLostPoints,
                      onChanged: (v) {
                        settings.fumbleLostPoints = v.toInt();
                        onSettingsChanged();
                      },
                      allowNegative: true,
                    ),
                    _ScoringInputData(
                      label: '2PT Conversion',
                      value: settings.twoPtConversion,
                      onChanged: (v) {
                        settings.twoPtConversion = v.toInt();
                        onSettingsChanged();
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<_ScoringInputData> inputs) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: colorScheme.primary)),
        const SizedBox(height: 4),
        ...inputs.map((input) => _ScoringInputRow(data: input)),
      ],
    );
  }
}

class _ScoringInputData {
  final String label;
  final num value;
  final ValueChanged<num> onChanged;
  final bool allowDecimal;
  final bool allowNegative;

  _ScoringInputData({
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowDecimal = false,
    this.allowNegative = false,
  });
}

class _ScoringInputRow extends StatelessWidget {
  final _ScoringInputData data;

  const _ScoringInputRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController(
      text: data.allowDecimal
          ? data.value.toStringAsFixed(1)
          : data.value.toInt().toString(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              data.label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withAlpha(204),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            height: 36,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(
                decimal: data.allowDecimal,
                signed: data.allowNegative,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onChanged: (text) {
                if (text.isEmpty) return;
                final parsed = data.allowDecimal
                    ? double.tryParse(text)
                    : int.tryParse(text);
                if (parsed != null) {
                  data.onChanged(parsed);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
