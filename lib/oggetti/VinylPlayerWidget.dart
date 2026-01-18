import 'package:flutter/material.dart';

typedef PlayerCallback = void Function();
typedef SkipCallback = void Function(bool forward);
typedef StopCallback = void Function();

class VinylPlayerWidget extends StatefulWidget {
  final String albumArtUrl;
  final bool isPlaying;
  final PlayerCallback onPlayPause;
  final SkipCallback onSkip;
  final StopCallback onStopPlayback;
  final double size;

  const VinylPlayerWidget({
    super.key,
    required this.albumArtUrl,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSkip,
    required this.onStopPlayback,
    this.size = 320.0,
  });

  @override
  State<VinylPlayerWidget> createState() => _VinylPlayerWidgetState();
}

class _VinylPlayerWidgetState extends State<VinylPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VinylPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Estetica disco
  Widget _buildVinylDisk(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Base del disco
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF121212),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: size * 0.09,
                spreadRadius: 2,
              ),
            ],
          ),
        ),

        // Scanalature del vinile
        for (int i = 0; i < 15; i++)
          Container(
            width: size - (i * (size * 0.056)),
            height: size - (i * (size * 0.056)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.04),
                width: 0.5,
              ),
            ),
          ),

        // Riflessi di luce
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Colors.white.withOpacity(0),
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0),
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
        ),

        Container(
          width: size * 0.38,
          height: size * 0.38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[900],
            border: Border.all(color: Colors.black, width: size * 0.0125),
          ),
          child: ClipOval(
            child: Image.network(
              widget.albumArtUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.music_note, color: Colors.white, size: size * 0.125),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: widget.onPlayPause,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < -300) {
            widget.onStopPlayback();
          }
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < -300) {
            widget.onSkip(true);
          } else if (details.primaryVelocity! > 300) {
            widget.onSkip(false);
          }
        },
        child: RotationTransition(
          turns: _controller,
          child: _buildVinylDisk(widget.size),
        ),
      ),
    );
  }
}