import 'package:flutter/material.dart';

class CustomTimelineCard extends StatelessWidget {
  final child;
  const CustomTimelineCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(25), //ensure the text does not touch the timeline
      //child: Text('Your order was received'),
      child: child,
    );
  }
}