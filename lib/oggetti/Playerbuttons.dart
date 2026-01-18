import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Playerbuttons extends StatelessWidget {
  double calc(double i, double perc) {
    return i / perc;
  }

  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final screensize = screenHeight * screenWidth;

    return Row(
      children: [
        IconButton(
          onPressed: () {},
          iconSize: screensize / calc(screensize, 40),
          color: Theme.of(context).colorScheme.secondary,
          icon: Icon(CupertinoIcons.backward_end_fill),
        ),
        IconButton(
          onPressed: () {},
          iconSize: screensize / calc(screensize, 50),
          color: Theme.of(context).colorScheme.secondary,
          icon: Icon(CupertinoIcons.arrowtriangle_right_fill),
        ),
        IconButton(
          onPressed: () {},
          iconSize: screensize / calc(screensize, 40),
          color: Theme.of(context).colorScheme.secondary,
          icon: Icon(CupertinoIcons.forward_end_fill),
        ),
      ],
    );
  }
}
