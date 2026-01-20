import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart'; 

class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final double scrollExtent;
  final double containerWidth;

  const ScrollingText({
    super.key,
    required this.text,
    required this.style,
    this.containerWidth = 80.0,
    this.duration = const Duration(seconds: 8),
    this.scrollExtent = 30.0,
  });

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  Timer? _animationStartDelayTimer;
  Timer? _animationEndDelayTimer;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _startScrollingWithDelay();
    });
  }

  @override
  void didUpdateWidget(covariant ScrollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _stopScrolling();
      _scrollController.jumpTo(0);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _startScrollingWithDelay();
      });
    }
  }
  
  void _startScrollingWithDelay() async {
    if (!_scrollController.hasClients) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
            _startScrollingWithDelay();
        });
        return;
    }
    
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    
    if (maxScrollExtent > 0) {
      
      // Il testo rimane fermo per 2 secondi
      _animationStartDelayTimer = Timer(const Duration(seconds: 2), () {
        
        if (!mounted || !_scrollController.hasClients) return;
        
        // Inizia a scorrere
        _scrollController.animateTo(
          maxScrollExtent + widget.scrollExtent,
          duration: widget.duration,
          curve: Curves.linear,
        ).then((_) {
          
          // Altra pausa di 2 secondi
          _animationEndDelayTimer = Timer(const Duration(seconds: 2), () {
            
            if (!mounted || !_scrollController.hasClients) return;
            
            // Torna alla posizione iniziale
            _scrollController.jumpTo(0);

            // Ricomincia
            _startScrollingWithDelay();
          });
        });
      });
    }
  }

  void _stopScrolling() {
    _animationStartDelayTimer?.cancel();
    _animationEndDelayTimer?.cancel();
  }

  @override
  void dispose() {
    _stopScrolling();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(), 
      child: Padding(
        padding: EdgeInsets.only(right: widget.scrollExtent),
        child: Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
        ),
      ),
    );
  }
}