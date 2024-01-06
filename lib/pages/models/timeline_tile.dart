// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:kickscorner_admin/pages/models/timeline_card.dart';
import 'package:timeline_tile/timeline_tile.dart';

class customTimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast; 
  final bool isPast;
  final customTimelineCard;
  const customTimelineTile({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.isPast,
    required this.customTimelineCard,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      //define the gap between the events or indicators
      height: 100,
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,
        //decorate the lines --> Color.fromARGB(255, 17, 168, 22)
        //if is past --> already handled show dark green shade. Otherwise show the lighter shade for tasks yet to be accomplished
        beforeLineStyle: LineStyle(color: isPast? Color.fromARGB(255, 17, 168, 22) : Color.fromARGB(255, 17, 168, 22).withOpacity(0.1)),
        //decorate the icon --> Color.fromARGB(255, 17, 168, 22) with white tick icon
        //hide the tick and use lighter indicator shade if the task is not yet accomplished
        indicatorStyle: IndicatorStyle(
          width: 40, 
          color: isPast? Color.fromARGB(255, 17, 168, 22) : Color.fromARGB(255, 17, 168, 22).withOpacity(0.1),
          iconStyle: IconStyle(
            iconData: Icons.done_rounded, 
            color: isPast? Colors.white : Color.fromARGB(255, 17, 168, 22).withOpacity(0.1)),
        ),
        //timeline event card or text --> shows the current order status text
        endChild: CustomTimelineCard(
          child: customTimelineCard,
        ),
      ),
    );
  }
}