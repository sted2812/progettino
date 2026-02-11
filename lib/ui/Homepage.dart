import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rpm/services/ContextServices.dart';
import 'package:rpm/services/MusicServices.dart';
import 'package:rpm/ui/TopBar.dart';
import 'package:rpm/main.dart';
import 'package:rpm/oggetti/HomeCarousel.dart';
import 'package:rpm/oggetti/HomeTop10.dart';
import 'package:rpm/localization/AppLocalization.dart';

double calc(double i, double perc) {
  if (perc == 0) return 0;
  return i / perc;
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Folder> _carouselFolders = [];
  List<Song> _top10Songs = [];
  bool _isReady = false;

  bool _isTop10Expanded = false;
  final ScrollController _top10ScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _refreshTop10() async {
    final topSongs = await MusicService.getTopSongs();
    if (mounted) {
      setState(() {
        _top10Songs = topSongs;
      });
    }
  }

  @override
  void dispose() {
    _top10ScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Recupera le cartelle speciali dal contextservice
    List<Folder> specialFolders = await ContextService.getActiveSpecialFolders();

    // Recupera cartelle preferite dal database
    List<Folder> favFolders = await MusicService.getFavoriteFolders();
    final Set<int> favIds = favFolders.map((f) => f.id).toSet();

    // Recupera tutte le cartelle utente per estrarne 3 random
    List<Folder> allUserFolders = await MusicService.getUserFolders();
    // Prendiamo quelle che non sono già state aggiunte come preferite
    List<Folder> remainingFolders = allUserFolders
        .where((f) => !favIds.contains(f.id))
        .toList();
    
    remainingFolders.shuffle();
    List<Folder> randomFolders = remainingFolders.take(3).toList();
    final topSongs = await MusicService.getTopSongs();

    if (mounted) {
      setState(() {
        _carouselFolders = [
          ...specialFolders,
          ...favFolders,
          ...randomFolders
        ];
        _top10Songs = topSongs;
        _isReady = true;
      });
    }
  }

  void _resetTop10() {
    MusicService.resetMonthlyStats();
    _refreshTop10();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final double titleBottom = screenHeight * 0.18;
    final double carouselHeight = 240.0; 
    final double top10ClosedTop = titleBottom + carouselHeight - 20;
    final double top10OpenedTop = titleBottom + 10;
    _refreshTop10();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Topbar(height: screenHeight * 0.85, width: screenWidth),
          Positioned(
            top: screenHeight * 0.0675,
            left: 20,
            child: Text(
              AppLocalization.of(context).translate("home_title"),
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),

          // Carousel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            top: titleBottom,
            left: 0,
            right: 0,
            height: carouselHeight,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isTop10Expanded ? 0.0 : 1.0,
              child: _isReady 
                ? HomeCarousel(
                    folders: _carouselFolders,
                  )
                : const Center(child: CupertinoActivityIndicator()),
            ),
          ),

          // Top 10
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
            top: _isTop10Expanded ? top10OpenedTop : top10ClosedTop,
            left: 20,
            right: 20,
            bottom: _isTop10Expanded ? 0 : null,
            height: _isTop10Expanded ? null : 340,
            child: HomeTop10(
              songs: _top10Songs,
              isExpanded: _isTop10Expanded,
              scrollController: _top10ScrollController,
              onReset: _resetTop10,
              onToggleExpansion: () {
                setState(() {
                  _isTop10Expanded = !_isTop10Expanded;
                });
                if (!_isTop10Expanded && _top10ScrollController.hasClients) {
                  _top10ScrollController.animateTo(
                    0, 
                    duration: const Duration(milliseconds: 500), 
                    curve: Curves.fastOutSlowIn
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}