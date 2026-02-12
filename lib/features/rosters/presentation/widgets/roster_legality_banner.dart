import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/roster_legality.dart';

/// A banner that displays roster legality warnings at the top of the lineup.
/// Shows empty slots, bye week conflicts, injured starters, and IR issues.
class RosterLegalityBanner extends StatefulWidget {
  final List<RosterLegalityWarning> warnings;

  const RosterLegalityBanner({
    super.key,
    required this.warnings,
  });

  @override
  State<RosterLegalityBanner> createState() => _RosterLegalityBannerState();
}

class _RosterLegalityBannerState extends State<RosterLegalityBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.warnings.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final warningCount =
        widget.warnings.where((w) => w.level == LegalityLevel.warning).length;
    final infoCount =
        widget.warnings.where((w) => w.level == LegalityLevel.info).length;

    final hasWarnings = warningCount > 0;

    final bannerColor = hasWarnings
        ? colorScheme.errorContainer.withAlpha(179)
        : colorScheme.tertiaryContainer.withAlpha(179);
    final borderColor = hasWarnings
        ? colorScheme.error.withAlpha(128)
        : colorScheme.tertiary.withAlpha(128);
    final iconColor =
        hasWarnings ? colorScheme.error : colorScheme.tertiary;
    final textColor = hasWarnings
        ? colorScheme.onErrorContainer
        : colorScheme.onTertiaryContainer;

    // Build summary text
    final parts = <String>[];
    if (warningCount > 0) {
      parts.add('$warningCount ${warningCount == 1 ? "issue" : "issues"}');
    }
    if (infoCount > 0) {
      parts.add('$infoCount ${infoCount == 1 ? "notice" : "notices"}');
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row (always visible)
          InkWell(
            onTap: widget.warnings.length > 1
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            borderRadius: AppSpacing.cardRadius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Icon(
                    hasWarnings ? Icons.warning_amber_rounded : Icons.info_outline,
                    color: iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasWarnings ? 'Lineup Issues' : 'Lineup Notices',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 13,
                          ),
                        ),
                        if (!_isExpanded && widget.warnings.length == 1)
                          Text(
                            widget.warnings.first.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withAlpha(200),
                            ),
                          )
                        else if (!_isExpanded)
                          Text(
                            parts.join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withAlpha(200),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.warnings.length > 1)
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: textColor.withAlpha(179),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),

          // Expanded list of warnings
          if (_isExpanded) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.warnings.map((warning) {
                  final isWarning = warning.level == LegalityLevel.warning;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isWarning
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline,
                          size: 14,
                          color: isWarning
                              ? colorScheme.error
                              : colorScheme.tertiary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                warning.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              if (warning.detail != null)
                                Text(
                                  warning.detail!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textColor.withAlpha(179),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
