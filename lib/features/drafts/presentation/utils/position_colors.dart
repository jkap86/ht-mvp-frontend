import 'package:flutter/material.dart';

Color getPositionColor(String position) {
  switch (position.toUpperCase()) {
    case 'QB':
      return Colors.red;
    case 'RB':
      return Colors.green;
    case 'WR':
      return Colors.blue;
    case 'TE':
      return Colors.orange;
    case 'K':
      return Colors.purple;
    case 'DEF':
      return Colors.brown;
    default:
      return Colors.grey;
  }
}
