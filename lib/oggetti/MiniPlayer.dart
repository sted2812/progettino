import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rpm/main.dart';
import 'package:rpm/services/MusicServices.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _isEjecting = false; 
  int _backwardTrigger = 0;
  int _forwardTrigger = 0;
  int _closeTrigger = 0; 

  double calc(double i, double perc) {
    if (perc == 0) return 0;
    return i / perc;
  }

  IconData _getIconForFolder(String name) {
    switch (name.toLowerCase()) {
      case "pioggia": case "smart_rain": return CupertinoIcons.umbrella_fill;
      case "soleggiato": case "smart_sunny": return CupertinoIcons.sun_haze_fill;
      case "musica in viaggio": case "smart_travel": return CupertinoIcons.car_fill;
      case "studio": case "smart_study": return CupertinoIcons.book_fill;
      case "relax": case "smart_relax": return CupertinoIcons.music_house_fill;
      case "giorno": case "smart_day": return CupertinoIcons.sun_max;
      case "pomeriggio": case "smart_afternoon": return CupertinoIcons.sunset_fill;
      case "sera": case "smart_evening": return CupertinoIcons.moon_fill;
      case "allenamento": case "smart_workout": return CupertinoIcons.bolt_fill;
      default: return CupertinoIcons.music_albums_fill; 
    }
  }

  void _handleEject() {
    MusicService.eject();
    setState(() {
      _isEjecting = true;
      _closeTrigger++;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isEjecting = false;
        });
      }
    });
  }

  void _handleSkip(bool forward) {
    setState(() {
      if (forward) _forwardTrigger++; else _backwardTrigger++;
    });
    if (forward) {
      MusicService.next();
    } else {
      MusicService.previous();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final screensize = screenHeight * screenWidth;

    final miniPlayerHeight = screenHeight * 0.175;
    final double bottomPosition = screenHeight * 0.13;

    return ValueListenableBuilder<Track?>(
      valueListenable: currentTrackNotifier,
      builder: (context, currentTrack, child) {
        if (currentTrack == null) return const SizedBox.shrink();

        return AnimatedSlide(
          offset: _isEjecting ? const Offset(0, -1.5) : Offset.zero,
          duration: const Duration(milliseconds: 375),
          curve: Curves.easeInBack, 
          child: AnimatedOpacity(
            opacity: _isEjecting ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            child: Stack(
              children: [
                Positioned(
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  bottom: bottomPosition,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const Scaffold(
                            body: Center(child: Text("Player Full Screen")),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: miniPlayerHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromARGB(255, 57, 51, 74).withOpacity(0.95)
                            : const Color.fromARGB(209, 171, 178, 231),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                          width: 0.75,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              _buildSongIcon(miniPlayerHeight * 0.7, currentTrack),
                              
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      currentTrack.title,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    Text(
                                      currentTrack.folderName,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    Text(
                                      currentTrack.artist ?? '',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                                        fontSize: 10,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    
                                    AnimatedBuilder(
                                      animation: Listenable.merge([
                                        MusicService.positionNotifier, 
                                        MusicService.loopModeNotifier, 
                                        MusicService.isShuffleNotifier, 
                                        currentTrackNotifier
                                      ]),
                                      builder: (context, _) {
                                        final bool enableBack = MusicService.hasPrevious();
                                        final bool enableForward = MusicService.hasNext();
                                        
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildPlayerButton(
                                              icon: CupertinoIcons.backward_fill,
                                              trigger: _backwardTrigger,
                                              onPressed: enableBack ? () => _handleSkip(false) : null,
                                              screensize: screensize,
                                              isEnabled: enableBack,
                                            ),
                                            const SizedBox(width: 10),
                                            
                                            ValueListenableBuilder<bool>(
                                              valueListenable: MusicService.isPlayingNotifier,
                                              builder: (context, isPlaying, _) {
                                                return IconButton(
                                                  onPressed: MusicService.togglePlayPause,
                                                  iconSize: screensize / calc(screensize, 46),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  color: Theme.of(context).colorScheme.secondary,
                                                  icon: AnimatedSwitcher(
                                                    duration: const Duration(milliseconds: 600),
                                                    transitionBuilder: (child, animation) =>
                                                        RotationTransition(
                                                          turns: animation,
                                                          child: ScaleTransition(scale: animation, child: child),
                                                        ),
                                                    switchInCurve: Curves.elasticOut,
                                                    child: Icon(
                                                      isPlaying 
                                                          ? CupertinoIcons.pause_fill 
                                                          : CupertinoIcons.arrowtriangle_right_fill,
                                                      key: ValueKey<bool>(isPlaying),
                                                    ),
                                                  ),
                                                );
                                              }
                                            ),
                                            
                                            const SizedBox(width: 10),
                                            _buildPlayerButton(
                                              icon: CupertinoIcons.forward_fill,
                                              trigger: _forwardTrigger,
                                              onPressed: enableForward ? () => _handleSkip(true) : null,
                                              screensize: screensize,
                                              isEnabled: enableForward,
                                            ),
                                          ],
                                        );
                                      }
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(width: miniPlayerHeight * 0.2),
                            ],
                          ),
                          
                          Positioned(
                            top: -5,
                            right: -5,
                            child: IconButton(
                              onPressed: _handleEject,
                              iconSize: 20,
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                switchInCurve: Curves.easeOut,
                                child: Icon(CupertinoIcons.eject_fill, key: ValueKey<int>(_closeTrigger)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongIcon(double size, Track track) {
    IconData iconData = _getIconForFolder(track.folderName);
    
    ImageProvider? imageProvider;
    if (track.imagePath != null && track.imagePath!.isNotEmpty) {
       if (track.imagePath!.startsWith('http')) {
         imageProvider = NetworkImage(track.imagePath!);
       } else {
         imageProvider = FileImage(File(track.imagePath!));
       }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        // Se c'è l'immagine, la mostra come sfondo del container
        image: imageProvider != null 
            ? DecorationImage(
                image: imageProvider, 
                fit: BoxFit.cover
              ) 
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Se non c'è immagine, mostra l'icona al centro
      child: imageProvider == null 
          ? Center(
              child: Icon(
                iconData,
                size: size * 0.5,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ),
            ) 
          : null,
    );
  }

  Widget _buildPlayerButton({
    required IconData icon, 
    required int trigger, 
    required VoidCallback? onPressed, 
    required double screensize,
    bool isEnabled = true
  }) {
    return IconButton(
      onPressed: onPressed,
      iconSize: screensize / calc(screensize, 46),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      color: isEnabled 
          ? Theme.of(context).colorScheme.secondary 
          : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        switchInCurve: Curves.easeOut,
        child: Icon(icon, key: ValueKey<int>(trigger)),
      ),
    );
  }
}