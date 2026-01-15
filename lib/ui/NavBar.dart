import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mp3/oggetti/MiniPlayer.dart';
import 'package:mp3/ui/Folderpage.dart';
import 'package:mp3/ui/Homepage.dart';
import 'package:mp3/ui/Playerpage.dart';
import 'package:mp3/main.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _AnimescionState();
}

class _AnimescionState extends State<Navbar> {
  int _selindex = 1;
  final List<Widget> _pages = [
    const Playerpage(),  // Index 0
    const Homepage(),    // Index 1
    const Folderpage(), // Index 2
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
          // Contenuto della Pagina Corrente
          IndexedStack(
            index: _selindex,
            children: _pages,
          ),
          
          // Logica del Miniplayer
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

          // Navigation Bar stile iOS
          Positioned(
            top: screenHeight * 0.89,
            left: screenWidth * 0.5 - 120,
            child: Container(
              padding: const EdgeInsets.all(0.5),
              height: 60,
              width: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 0.75,
                ),
                borderRadius: BorderRadius.circular(90),
                color: const Color.fromARGB(41, 80, 70, 157),
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
                        color: const Color.fromARGB(59, 107, 98, 152),
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