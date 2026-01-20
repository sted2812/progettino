import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mp3/main.dart'; 
import 'package:mp3/services/MusicServices.dart'; 
import 'package:mp3/oggetti/ScrollingText.dart';

class SongsListPage extends StatefulWidget {
  final String folderName;
  final List<Song>? preloadedSongs; 
  
  const SongsListPage({
    super.key, 
    required this.folderName, 
    this.preloadedSongs
  });

  @override
  State<SongsListPage> createState() => _SongsListPageState();
}

class _SongsListPageState extends State<SongsListPage> {
  List<Song> _songs = [];
  bool _isLoading = true;
  
  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedSongs != null) {
      _songs = widget.preloadedSongs!;
      _isLoading = false;
    } else {
      _loadSongs();
    }
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final songs = await MusicService.getSongsInFolder(widget.folderName);
    if (mounted) {
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    }
  }

  void _deleteSong(Song song) async {
    await MusicService.deleteSong(song.id);
    _loadSongs(); 
  }
  
  void _renameSong(Song song, String newName) async {
    await MusicService.renameSong(song.id, newName);
    _loadSongs(); 
  }

  void _pickImageForSong(Song song) async {
    final String? imagePath = await MusicService.pickImageFromDevice();
    if (imagePath != null) {
      await MusicService.updateSongImage(song.id, imagePath);
      _loadSongs();
    }
  }

  void _playSong(BuildContext context, Song song) {
    MusicService.playTrack(song, _songs);
  }

  void _showSongContextMenu(Song song) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    double left = _tapPosition.dx;
    double top = _tapPosition.dy;
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (left > screenWidth - 220) left = screenWidth - 220;

    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(left, top, 40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.transparent,
      elevation: 0,
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            width: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2), 
                width: 1.5
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Column(
                    children: [
                      Text(
                        song.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      if (song.artist != null)
                        Text(
                          song.artist!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                _buildInlineMenuItem("Rinomina", CupertinoIcons.pencil, () => _showRenameDialog(song)),
                _buildInlineMenuItem("Modifica immagine", CupertinoIcons.photo, () => _pickImageForSong(song)),
                _buildInlineMenuItem("Aggiungi ai preferiti", CupertinoIcons.star, () { /* Placeholder preferiti */ }),
                
                _buildInlineMenuItem(
                  "Elimina", 
                  CupertinoIcons.delete, 
                  () => _showDeleteConfirmDialog(song), 
                  color: Colors.redAccent, 
                  textColor: Colors.redAccent
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineMenuItem(String text, IconData icon, VoidCallback action, {Color? color, Color? textColor}) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        action();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text, 
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.w500,
                  color: textColor ?? color ?? Theme.of(context).colorScheme.secondary,
                  decoration: TextDecoration.none,
                )
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Song song) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text("Elimina brano?", style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        content: Text("Sei sicuro di voler eliminare '${song.title}'?", style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        actions: [
          CupertinoDialogAction(
            child: const Text("Annulla", style: TextStyle(color: CupertinoColors.activeBlue)), 
            onPressed: () => Navigator.pop(ctx)
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Elimina"),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSong(song);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(Song song) {
    final controller = TextEditingController(text: song.title);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text("Rinomina", style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: controller, 
            autofocus: true, 
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(child: const Text("Annulla", style: TextStyle(color: CupertinoColors.activeBlue)), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            child: const Text("Salva", style: TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.bold)), 
            onPressed: () {
              if (controller.text.isNotEmpty) {
                 _renameSong(song, controller.text);
              }
              Navigator.pop(ctx);
            }
          ),
        ],
      ),
    );
  }

  Widget _buildGridTextWidget(String text, TextStyle style) {
    const int maxCharsBeforeScroll = 13;
    const double fixedWidth = 80.0;
    
    if (text.length <= maxCharsBeforeScroll) {
      return Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    
    return SizedBox(
      width: fixedWidth,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.05, 0.95, 1.0], 
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ScrollingText(
          text: " " + text,
          style: style,
          duration: Duration(seconds: 3 + (text.length ~/ 5)), 
          scrollExtent: 20.0, 
        ),
      ),
    );
  }

  Widget _buildPageTitle(BuildContext context, String text) {
    const int maxCharsForStaticTitle = 18; 
    final screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - 70;

    if (text.length <= maxCharsForStaticTitle) {
      return Text(
        text,
        textAlign: TextAlign.left,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      );
    }

    return SizedBox(
      width: availableWidth,
      child: ScrollingText(
        text: text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
        duration: const Duration(seconds: 10),
        scrollExtent: 50.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor, 
            ),
          ),
          
          // Pannello principale con la griglia dei brani
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenHeight * 0.85,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  width: 0.5
                ),
              ),
              padding: EdgeInsets.only(top: screenHeight * 0.055),
              child: _isLoading 
                ? const Center(child: CupertinoActivityIndicator())
                : _songs.isEmpty 
                  ? Center(
                      child: Text(
                        "Cartella vuota",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)
                        )
                      )
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, 
                        childAspectRatio: 0.65, 
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 30,
                      ),
                      itemCount: _songs.length, 
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        return GestureDetector(
                          onTapDown: (details) => _tapPosition = details.globalPosition,
                          onLongPress: () => _showSongContextMenu(song),
                          child: Column(
                            children: [
                              Container(
                                height: 80, width: 80,
                                decoration: BoxDecoration(
                                  color: isDarkMode 
                                      ? Colors.white.withOpacity(0.05) 
                                      : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  image: song.imagePath != null
                                    ? DecorationImage(
                                        image: NetworkImage(song.imagePath!), 
                                        fit: BoxFit.cover
                                      )
                                    : null,
                                ),
                                child: song.imagePath == null
                                  ? Icon(
                                      Icons.audiotrack, 
                                      size: 45, 
                                      color: Theme.of(context).colorScheme.secondary
                                    )
                                  : null,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 80, 
                                height: 22, 
                                child: _buildGridTextWidget(song.title, TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                )),
                              ),
                              if (song.artist != null)
                                SizedBox(
                                  width: 80, 
                                  height: 18, 
                                  child: _buildGridTextWidget(song.artist!, TextStyle(
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                                    fontSize: 10,
                                    decoration: TextDecoration.none,
                                  )),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          Positioned(
            top: screenHeight * 0.08,
            left: 10,
            right: 60,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                  stops: [0.0, 0.04, 0.92, 1.0], 
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: _buildPageTitle(context, " " + widget.folderName), 
            ),
          ),
          
          Positioned(
            top: screenHeight * 0.0775,
            right: 10,
            child: IconButton(
              icon: Icon(
                CupertinoIcons.fullscreen_exit,
                size: 36, 
                color: Theme.of(context).colorScheme.secondary
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}