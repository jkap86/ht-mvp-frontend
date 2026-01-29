import 'package:flutter/material.dart';

import '../../domain/draft_order_entry.dart';

/// Header widget for the fast auction panel showing nominator info and budget.
class FastAuctionHeader extends StatelessWidget {
  final DraftOrderEntry? nominator;
  final bool isMyNomination;
  final int nominationNumber;
  final int? myBudgetAvailable;

  const FastAuctionHeader({
    super.key,
    required this.nominator,
    required this.isMyNomination,
    required this.nominationNumber,
    this.myBudgetAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMyNomination ? Colors.deepPurple[100] : Colors.deepPurple[50],
        border: Border(bottom: BorderSide(color: Colors.deepPurple[200]!)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.gavel,
            size: 20,
            color: isMyNomination ? Colors.deepPurple : Colors.deepPurple[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMyNomination
                      ? 'Your Turn to Nominate'
                      : 'Waiting for ${nominator?.username ?? 'Unknown'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color:
                        isMyNomination ? Colors.deepPurple : Colors.deepPurple[700],
                  ),
                ),
                Text(
                  'Nomination #$nominationNumber',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple[400],
                  ),
                ),
              ],
            ),
          ),
          if (myBudgetAvailable != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\$$myBudgetAvailable',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
