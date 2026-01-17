import 'package:flutter/material.dart';

class Topbar extends StatelessWidget {

  final double height;
  final double width;

  Topbar({super.key, required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            alignment: Alignment.bottomCenter,
            height: height,
            width: width,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              color: Theme.of(context).colorScheme.primary,
            ),
            padding: EdgeInsets.only(top: height * 0.055),
          ),
        ),
      ],
    );
  }
}
