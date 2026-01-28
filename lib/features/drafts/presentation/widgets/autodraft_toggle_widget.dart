import 'package:flutter/material.dart';

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
    return Tooltip(
      message: isEnabled
          ? 'Autodraft is ON: Picks will be made automatically when timer expires'
          : 'Autodraft is OFF: You will need to make picks manually',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.green[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled ? Colors.green : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flash_auto,
              size: 18,
              color: isEnabled ? Colors.green[700] : Colors.grey[600],
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
                  activeColor: Colors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
