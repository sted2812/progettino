import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mp3/services/ContextServices.dart';
import 'package:mp3/services/MusicServices.dart';
import 'package:mp3/ui/TopBar.dart';
import 'package:mp3/main.dart';
import 'package:mp3/oggetti/HomeCarousel.dart';
import 'package:mp3/oggetti/HomeTop10.dart';

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
  // Dati
  List<Folder> _carouselFolders = [];
  List<Song> _top10Songs = [];
  bool _isReady = false;

  // Stato per l'espansione della Top 10
  bool _isTop10Expanded = false;
  final ScrollController _top10ScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Metodo per ricaricare la classifica (utile per aggiornare i conteggi)
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
    // 1. Recupera le cartelle speciali dal ContextService (Meteo, Luoghi, Viaggio, ecc.)
    List<Folder> specialFolders = await ContextService.getActiveSpecialFolders();

    // 2. Recupera cartelle preferite dal DB
    List<Folder> favFolders = await MusicService.getFavoriteFolders();
    final Set<int> favIds = favFolders.map((f) => f.id).toSet();

    // 3. Recupera tutte le cartelle utente per estrarne 3 random
    List<Folder> allUserFolders = await MusicService.getUserFolders();
    // Prendiamo quelle che NON sono già state aggiunte come preferite
    List<Folder> remainingFolders = allUserFolders
        .where((f) => !favIds.contains(f.id))
        .toList();
    
    remainingFolders.shuffle();
    List<Folder> randomFolders = remainingFolders.take(3).toList();

    // 4. Carica la Top 10 reale dal servizio
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
    
    // --- POSIZIONI E DIMENSIONI ---
    final double titleBottom = screenHeight * 0.18; 
    
    // Altezza del carousel
    final double carouselHeight = 240.0; 
    
    // Top 10 CHIUSA: Inizia subito sotto il carousel (ridotto il gap per alzarla)
    final double top10ClosedTop = titleBottom + carouselHeight - 20;
    
    // Top 10 APERTA: Inizia subito sotto il titolo Home
    final double top10OpenedTop = titleBottom + 10;

    // Ricarica la classifica ogni volta che la home viene ricostruita
    _refreshTop10();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Sfondo TopBar
          Topbar(height: screenHeight * 0.85, width: screenWidth),
          
          // 2. Titolo Home
          Positioned(
            top: screenHeight * 0.08,
            left: 20,
            child: Text(
              'Home',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 3. CAROUSEL PLAYLIST (Widget Separato)
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
                    // Passiamo una mappa vuota o default perché le info sono già dentro Folder.name
                    // HomeCarousel si occupa di mappare l'icona in base al nome
                    smartRec: const {}, 
                  )
                : const Center(child: CupertinoActivityIndicator()),
            ),
          ),

          // 4. RIQUADRO TOP 10 (Widget Separato)
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