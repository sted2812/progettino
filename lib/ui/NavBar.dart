import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:RPM/oggetti/MiniPlayer.dart';
import 'package:RPM/ui/Folderpage.dart';
import 'package:RPM/ui/HomePage.dart';
import 'package:RPM/ui/PlayerPage.dart';
import 'package:RPM/main.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selindex = 1;

  final List<Widget> _pages = [
    const Playerpage(),
    const Homepage(),
    const Folderpage(),
  ];

  void _onTap(int index) {
    setState(() => _selindex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final bool isPlayerPage = _selindex == 0;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selindex,
            children: _pages,
          ),
          
          if (!isPlayerPage)
            ValueListenableBuilder<Track?>(
              valueListenable: currentTrackNotifier,
              builder: (context, track, child) {
                if (track != null) {
                  return const MiniPlayer();
                }
                return const SizedBox.shrink();
              },
            ),

          // Navigation bar
          Positioned(
            top: screenHeight * 0.89,
            left: screenWidth * 0.5 - 120,
            child: Container(
              padding: const EdgeInsets.all(0.5),
              height: 60,
              width: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.25),
                  width: 0.75,
                ),
                borderRadius: BorderRadius.circular(90),
                color: (Theme.of(context).brightness == Brightness.dark) ? const Color.fromARGB(202, 69, 64, 99) : const Color.fromARGB(209, 171, 178, 231),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 100),
                    alignment: _selindex == 0
                        ? const Alignment(-0.93, 0)
                        : _selindex == 1
                            ? const Alignment(0, 0)
                            : const Alignment(0.93, 0),
                    child: Container(
                      width: 80,
                      height: 50,
                      decoration: BoxDecoration(
                        color: (Theme.of(context).brightness == Brightness.dark) ? const Color.fromARGB(59, 107, 98, 152) : const Color.fromARGB(58, 98, 112, 152),
                        borderRadius: BorderRadius.circular(45),
                      ),
                    ),
                  ),
                  
                  Align(
                    alignment: const Alignment(-0.8, 0),
                    child: IconButton(
                      onPressed: () => _onTap(0),
                      iconSize: 37,
                      color: _selindex == 0
                          ? Colors.blueAccent[200]
                          : Theme.of(context).colorScheme.secondary,
                      icon: const Icon(CupertinoIcons.music_note),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 0),
                    child: IconButton(
                      onPressed: () => _onTap(1),
                      iconSize: 35,
                      color: _selindex == 1
                          ? Colors.blueAccent[200]
                          : Theme.of(context).colorScheme.secondary,
                      icon: const Icon(CupertinoIcons.house_fill),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0.8, 0),
                    child: IconButton(
                      onPressed: () => _onTap(2),
                      iconSize: 35,
                      color: _selindex == 2
                          ? Colors.blueAccent[200]
                          : Theme.of(context).colorScheme.secondary,
                      icon: const Icon(CupertinoIcons.folder_fill),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}