import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';

/// A toggle switch for enabling/disabling autodraft.
/// When enabled, the system will automatically make picks from the user's queue
/// (or best available player) when their turn timer expires.
class AutodraftToggleWidget extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback? onToggle;

  const AutodraftToggleWidget({
    super.key,
    required this.isEnabled,
    this.isLoading = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: isEnabled
          ? 'Autodraft is ON: Picks will be made automatically when timer expires'
          : 'Autodraft is OFF: You will need to make picks manually',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isEnabled
              ? context.htColors.draftAction.withAlpha(25)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.pillRadius,
          border: Border.all(
            color: isEnabled
                ? context.htColors.draftAction
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flash_auto,
              size: 18,
              color: isEnabled
                  ? context.htColors.draftAction
                  : theme.colorScheme.onSurfaceVariant,
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              SizedBox(
                height: 24,
                child: Switch(
                  value: isEnabled,
                  onChanged: onToggle != null ? (_) => onToggle!() : null,
                  activeColor: context.htColors.draftAction,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
