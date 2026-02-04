import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dues_provider.dart';

/// Represents a single payout entry with a key and percentage
class PayoutEntry {
  final String key;
  final String label;
  final TextEditingController controller;

  PayoutEntry({
    required this.key,
    required this.label,
    String? initialValue,
  }) : controller = TextEditingController(text: initialValue ?? '0');

  void dispose() {
    controller.dispose();
  }
}

/// Available payout options
const _payoutOptions = [
  ('1st', '1st Place'),
  ('2nd', '2nd Place'),
  ('3rd', '3rd Place'),
  ('4th', '4th Place'),
  ('Most Points', 'Most Points'),
  ('Weekly High', 'Weekly High Score'),
];

/// Card for configuring league dues (commissioner only)
class DuesConfigCard extends ConsumerStatefulWidget {
  final int leagueId;
  final int totalRosters;

  const DuesConfigCard({
    super.key,
    required this.leagueId,
    required this.totalRosters,
  });

  @override
  ConsumerState<DuesConfigCard> createState() => _DuesConfigCardState();
}

class _DuesConfigCardState extends ConsumerState<DuesConfigCard> {
  final _formKey = GlobalKey<FormState>();
  final _buyInController = TextEditingController();
  final _notesController = TextEditingController();

  /// Dynamic list of payout entries
  final List<PayoutEntry> _payouts = [];

  bool _isEnabled = false;
  bool _isInitialized = false;
  DateTime? _lastConfigUpdatedAt;

  @override
  void initState() {
    super.initState();
    // Initialize with 1st place by default
    _payouts.add(PayoutEntry(key: '1st', label: '1st Place', initialValue: '100'));
    Future.microtask(() => ref.read(duesProvider(widget.leagueId).notifier).loadDues());
  }

  @override
  void dispose() {
    _buyInController.dispose();
    _notesController.dispose();
    for (final payout in _payouts) {
      payout.dispose();
    }
    super.dispose();
  }

  void _initializeFromState(DuesState state) {
    final configUpdatedAt = state.config?.updatedAt;
    // Allow re-init if config was updated externally (e.g., from another device)
    if (_isInitialized && _lastConfigUpdatedAt == configUpdatedAt) return;
    _isInitialized = true;
    _lastConfigUpdatedAt = configUpdatedAt;

    if (state.config != null) {
      _isEnabled = true;
      _buyInController.text = state.config!.buyInAmount.toStringAsFixed(2);
      _notesController.text = state.config!.notes ?? '';

      // Clear existing payouts and rebuild from state
      for (final payout in _payouts) {
        payout.dispose();
      }
      _payouts.clear();

      final structure = state.config!.payoutStructure;
      for (final entry in structure.entries) {
        final option = _payoutOptions.firstWhere(
          (opt) => opt.$1 == entry.key,
          orElse: () => (entry.key, entry.key),
        );
        _payouts.add(PayoutEntry(
          key: option.$1,
          label: option.$2,
          initialValue: entry.value.toString(),
        ));
      }

      // Ensure 1st place is always present
      if (!_payouts.any((p) => p.key == '1st')) {
        _payouts.insert(
          0,
          PayoutEntry(key: '1st', label: '1st Place', initialValue: '100'),
        );
      }
    }
  }

  /// Get payout options that haven't been added yet
  List<(String, String)> get _availablePayoutOptions {
    final usedKeys = _payouts.map((p) => p.key).toSet();
    return _payoutOptions.where((opt) => !usedKeys.contains(opt.$1)).toList();
  }

  /// Add a new payout entry
  void _addPayout(String key, String label) {
    setState(() {
      _payouts.add(PayoutEntry(key: key, label: label, initialValue: '0'));
    });
  }

  /// Remove a payout entry (cannot remove 1st place)
  void _removePayout(int index) {
    if (_payouts[index].key == '1st') return;
    setState(() {
      _payouts[index].dispose();
      _payouts.removeAt(index);
    });
  }

  /// Calculate total percentage of all payouts
  double get _totalPercentage {
    double total = 0;
    for (final payout in _payouts) {
      total += double.tryParse(payout.controller.text) ?? 0;
    }
    return total;
  }

  /// Build payout structure map for saving
  Map<String, num> _buildPayoutStructure() {
    final structure = <String, num>{};
    for (final payout in _payouts) {
      final value = double.tryParse(payout.controller.text) ?? 0;
      if (value > 0) {
        structure[payout.key] = value;
      }
    }
    return structure;
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final buyIn = double.tryParse(_buyInController.text) ?? 0;
    final totalPercentage = _totalPercentage;

    if (totalPercentage > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout percentages cannot exceed 100%'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await ref.read(duesProvider(widget.leagueId).notifier).saveDuesConfig(
          buyInAmount: buyIn,
          payoutStructure: _buildPayoutStructure(),
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Dues configuration saved' : 'Failed to save configuration'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _disableDues() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Dues Tracking'),
        content: const Text(
          'This will disable dues tracking and remove all payment records. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref.read(duesProvider(widget.leagueId).notifier).deleteDuesConfig();

    if (!mounted) return;

    if (success) {
      setState(() {
        _isEnabled = false;
        _isInitialized = false;
        _buyInController.clear();
        _notesController.clear();
        // Reset payouts to default (1st place only)
        for (final payout in _payouts) {
          payout.dispose();
        }
        _payouts.clear();
        _payouts.add(PayoutEntry(key: '1st', label: '1st Place', initialValue: '100'));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dues tracking disabled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duesProvider(widget.leagueId));
    final colorScheme = Theme.of(context).colorScheme;

    // Initialize form fields from state
    if (!state.isLoading && state.overview != null) {
      _initializeFromState(state);
    }

    // Calculate totals for display - use backend's totalCount which excludes benched teams
    final buyIn = double.tryParse(_buyInController.text) ?? 0;
    final activeRosterCount = state.summary?.totalCount ?? widget.totalRosters;
    final totalPot = buyIn * activeRosterCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on),
                const SizedBox(width: 8),
                Text(
                  'League Dues',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),

            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enable toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable dues tracking'),
                      subtitle: Text(
                        _isEnabled
                            ? 'Track member payments for league buy-ins'
                            : 'Turn on to set up league dues',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: _isEnabled,
                      onChanged: (value) {
                        setState(() => _isEnabled = value);
                        if (!value && state.isEnabled) {
                          _disableDues();
                        }
                      },
                    ),

                    if (_isEnabled) ...[
                      const SizedBox(height: 16),

                      // Buy-in amount
                      TextFormField(
                        controller: _buyInController,
                        decoration: const InputDecoration(
                          labelText: 'Buy-in Amount',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a buy-in amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount < 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 16),

                      // Payout structure
                      Text(
                        'Payout Structure',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // Dynamic payout entries
                      ...List.generate(_payouts.length, (index) {
                        final payout = _payouts[index];
                        final canDelete = payout.key != '1st';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: payout.controller,
                                  decoration: InputDecoration(
                                    labelText: payout.label,
                                    suffixText: '%',
                                    border: const OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              if (canDelete) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _removePayout(index),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Remove payout',
                                  style: IconButton.styleFrom(
                                    foregroundColor: colorScheme.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),

                      // Add payout button
                      if (_availablePayoutOptions.isNotEmpty)
                        PopupMenuButton<(String, String)>(
                          onSelected: (option) => _addPayout(option.$1, option.$2),
                          itemBuilder: (context) => _availablePayoutOptions
                              .map((opt) => PopupMenuItem(
                                    value: opt,
                                    child: Text(opt.$2),
                                  ))
                              .toList(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Add Payout',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Payout preview
                      if (buyIn > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Pot: \$${totalPot.toStringAsFixed(2)} ($activeRosterCount teams)',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: _payouts.map((payout) {
                                  final pct = double.tryParse(payout.controller.text) ?? 0;
                                  if (pct <= 0) return const SizedBox.shrink();
                                  return Text(
                                    '${payout.label}: \$${(totalPot * pct / 100).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (_totalPercentage > 100) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Warning: Total is ${_totalPercentage.toStringAsFixed(0)}% (exceeds 100%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          hintText: 'e.g., Pay via Venmo @commish',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        maxLength: 500,
                      ),

                      const SizedBox(height: 16),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: state.isSaving ? null : _saveConfig,
                          child: state.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
