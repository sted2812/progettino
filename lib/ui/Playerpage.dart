import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:RPM/oggetti/VinylPlayerWidget.dart';
import 'package:RPM/oggetti/cricket.dart';
import 'package:RPM/ui/TopBar.dart';
import 'package:RPM/main.dart'; 
import 'package:RPM/services/MusicServices.dart';
import 'package:RPM/localization/AppLocalization.dart'; 

double calc(double i, double perc) {
  if (perc == 0) return 0;
  if (perc < 1) return i; 
  return i / perc;
}

class Playerpage extends StatefulWidget {
  const Playerpage({super.key});

  @override
  State<Playerpage> createState() => _PlayerpageState();
}

class _PlayerpageState extends State<Playerpage> {
  int _backwardTrigger = 0;
  int _forwardTrigger = 0;
  
  Offset _transitionOffset = Offset.zero;
  double _rotationDirection = 1.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleSkip(bool forward) {
    setState(() {
      _rotationDirection = forward ? 1.0 : -1.0;
      _transitionOffset = forward ? const Offset(-1.2, 0) : const Offset(1.2, 0);
      
      if (forward) {
        _forwardTrigger++;
        MusicService.next();
      } else {
        _backwardTrigger++;
        MusicService.previous();
      }
    });
  }

  void _handleEject() {
    MusicService.eject();
    setState(() {
      _transitionOffset = const Offset(0, -1.5);
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        currentTrackNotifier.value = null;
        MusicService.resetPosition();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final screensize = screenHeight * screenWidth;

    double vinylSize = screenWidth * 0.72;
    double maxVinylAvailableHeight = screenHeight * 0.35; 
    if (vinylSize > maxVinylAvailableHeight) vinylSize = maxVinylAvailableHeight;
    double vinylTop = screenHeight * 0.18 + (maxVinylAvailableHeight - vinylSize) / 2;
    final double iconSize = (screensize > 0) ? screensize / calc(screensize, 60) : 40.0;
    final double safeIconSize = (iconSize.isNaN || iconSize.isInfinite || iconSize < 10) ? 50.0 : iconSize;


    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Topbar(height: screenHeight * 0.4, width: screenWidth),
          
          Positioned(
            top: screenHeight * 0.07,
            left: 20,
            child: Text(
              AppLocalization.of(context).translate("player_title"),
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
                fontFamily: 'Arial',
              ),
            ),
          ),

          // Area disco
          Positioned(
            top: vinylTop,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: MusicService.isPlayingNotifier,
              builder: (context, isPlaying, _) {
                return ValueListenableBuilder<Track?>(
                  valueListenable: currentTrackNotifier,
                  builder: (context, track, child) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                        return Stack(
                          alignment: Alignment.center,
                          children: <Widget>[...previousChildren, if (currentChild != null) currentChild],
                        );
                      },
                      transitionBuilder: (Widget transitionChild, Animation<double> animation) {
                        final currentId = track?.id ?? -1;
                        final isEntering = transitionChild.key == ValueKey(currentId);

                        if (isEntering) {
                          return RotationTransition(
                            turns: Tween<double>(begin: -_rotationDirection, end: 0.0).animate(animation),
                            child: FadeTransition(opacity: animation, child: transitionChild),
                          );
                        } else {
                          return RotationTransition(
                            turns: Tween<double>(begin: 0.0, end: _rotationDirection).animate(animation),
                            child: FadeTransition(opacity: animation, child: transitionChild),
                          );
                        }
                      },
                      child: track == null 
                        ? Container(
                            key: const ValueKey(-1),
                            height: vinylSize,
                            width: vinylSize,
                            child: Center(
                              child: Icon(
                                MyFlutterApp.cricket,
                                size: vinylSize * 0.4,
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                              ),
                            ),
                          ) 
                        : VinylPlayerWidget(
                            key: ValueKey(track.id),
                            size: vinylSize,
                            albumArtUrl: track.imagePath ?? '',
                            isPlaying: isPlaying,
                            onPlayPause: MusicService.togglePlayPause,
                            onSkip: _handleSkip,
                            onStopPlayback: _handleEject,
                          ),
                    );
                  },
                );
              },
            ),
          ),

          // info brano
          Positioned(
            top: screenHeight * 0.62, 
            left: 20,
            right: 20,
            child: ValueListenableBuilder<Track?>(
              valueListenable: currentTrackNotifier,
              builder: (context, currentTrack, child) {
                if (currentTrack == null) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalization.of(context).translate("player_no_track"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Arial',
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalization.of(context).translate("player_silence_msg"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                          fontSize: 16,
                          fontFamily: 'Arial',
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentTrack.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 26, 
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Arial',
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      "${currentTrack.artist ?? AppLocalization.of(context).translate('common_unknown_artist')} • ${currentTrack.folderName}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Arial',
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // barra di avanzamento
          Positioned(
            top: screenHeight * 0.70,
            left: 25,
            right: 25,
            child: ValueListenableBuilder<Track?>(
              valueListenable: currentTrackNotifier,
              builder: (context, track, child) {
                if (track == null) return const SizedBox.shrink();
                
                return ValueListenableBuilder<Duration>(
                  valueListenable: MusicService.positionNotifier,
                  builder: (context, position, _) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: MusicService.durationNotifier,
                      builder: (context, duration, _) {
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                activeTrackColor: Theme.of(context).colorScheme.secondary,
                                inactiveTrackColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                thumbColor: Theme.of(context).colorScheme.secondary,
                              ),
                              child: Slider(
                                value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                                max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
                                onChanged: (value) {
                                  MusicService.seek(Duration(seconds: value.toInt()));
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(0.6), fontSize: 12, fontFamily: 'Arial', decoration: TextDecoration.none),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDuration(duration),
                                    style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(0.6), fontSize: 12, fontFamily: 'Arial', decoration: TextDecoration.none),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    );
                  }
                );
              },
            ),
          ),

          // controlli di riproduzione
          Positioned(
            top: screenHeight * 0.78 - (safeIconSize * 0.5),
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                MusicService.positionNotifier, 
                MusicService.loopModeNotifier, 
                MusicService.isShuffleNotifier,
                currentTrackNotifier,
                MusicService.isPlayingNotifier
              ]),
              builder: (context, _) {
                final bool enableBack = MusicService.hasPrevious();
                final bool enableForward = MusicService.hasNext();
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: MusicService.toggleShuffle,
                      icon: Icon(
                        CupertinoIcons.shuffle,
                        color: MusicService.isShuffleNotifier.value ? Colors.blue : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 5), 
                    
                    IconButton(
                      onPressed: enableBack ? () => _handleSkip(false) : null,
                      iconSize: safeIconSize,
                      color: enableBack 
                          ? Theme.of(context).colorScheme.secondary 
                          : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: Icon(CupertinoIcons.backward_fill, key: ValueKey(_backwardTrigger)),
                      ),
                    ),
                    const SizedBox(width: 8), 
                    
                    ValueListenableBuilder<bool>(
                      valueListenable: MusicService.isPlayingNotifier,
                      builder: (context, isPlaying, child) {
                        return IconButton(
                          onPressed: MusicService.togglePlayPause,
                          iconSize: safeIconSize,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: Theme.of(context).colorScheme.secondary,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return RotationTransition(
                                turns: animation,
                                child: ScaleTransition(scale: animation, child: child),
                              );
                            },
                            child: SizedBox(
                              width: safeIconSize,
                              height: safeIconSize,
                              key: ValueKey(isPlaying),
                              child: Center(
                                child: Icon(
                                  isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.arrowtriangle_right_fill,
                                  size: safeIconSize,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                    const SizedBox(width: 8), 
                    
                    IconButton(
                      onPressed: enableForward ? () => _handleSkip(true) : null,
                      iconSize: safeIconSize,
                      color: enableForward 
                          ? Theme.of(context).colorScheme.secondary 
                          : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: Icon(CupertinoIcons.forward_fill, key: ValueKey(_forwardTrigger)),
                      ),
                    ),
                    const SizedBox(width: 5), 
                    
                    GestureDetector(
                      onTap: MusicService.toggleLoop,
                      onLongPress: MusicService.activateSingleLoop,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          MusicService.loopModeNotifier.value == LoopMode.single 
                              ? CupertinoIcons.repeat_1 
                              : CupertinoIcons.repeat,
                          color: MusicService.loopModeNotifier.value == LoopMode.none ? Colors.grey : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}