import 'package:flutter/material.dart';

class RecentPicksWidget extends StatelessWidget {
  final List<Map<String, dynamic>> picks;

  const RecentPicksWidget({super.key, required this.picks});

  @override
  Widget build(BuildContext context) {
    if (picks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Recent Picks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: picks.length,
              itemBuilder: (context, index) {
                final pick = picks[picks.length - 1 - index];
                return _PickCard(pick: pick);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  final Map<String, dynamic> pick;

  const _PickCard({required this.pick});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${pick['pick_number']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'R${pick['round']}P${pick['pick_in_round']}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
