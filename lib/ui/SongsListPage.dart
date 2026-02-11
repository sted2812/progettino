import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:RPM/main.dart';
import 'package:RPM/services/MusicServices.dart';
import 'package:RPM/oggetti/ScrollingText.dart';
import 'package:RPM/localization/AppLocalization.dart';

class SongsListPage extends StatefulWidget {
  final String folderName;
  final List<Song>? preloadedSongs;

  const SongsListPage({
    super.key,
    required this.folderName,
    this.preloadedSongs,
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

  void _renameArtist(Song song, String newArtist) async {
    await MusicService.updateSongArtist(song.id, newArtist);
    _loadSongs();
  }

  void _pickImageForSong(Song song) async {
    final String? imagePath = await MusicService.pickImageFromDevice();
    if (imagePath != null) {
      await MusicService.updateSongImage(song.id, imagePath);
      _loadSongs();
    }
  }

  void _resetImageForSong(Song song) async {
    await MusicService.updateSongImage(song.id, null);
    _loadSongs();
  }

  void _playSong(BuildContext context, Song song) {
    MusicService.playTrack(song, _songs);
  }

  void _showSongContextMenu(Song song) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
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
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
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
                          fontFamily: 'Arial',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (song.artist != null)
                        Text(
                          song.artist!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.6),
                            decoration: TextDecoration.none,
                            fontFamily: 'Arial',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                _buildInlineMenuItem(
                  AppLocalization.of(context).translate("common_rename"),
                  CupertinoIcons.pencil,
                  () => _showRenameDialog(song),
                ),
                _buildInlineMenuItem(
                  AppLocalization.of(context).translate("context_menu_artist"),
                  CupertinoIcons.person_crop_circle,
                  () => _showArtistDialog(song),
                ),
                _buildInlineMenuItem(
                  AppLocalization.of(
                    context,
                  ).translate("context_menu_choose_image"),
                  CupertinoIcons.photo,
                  () => _pickImageForSong(song),
                ),

                if (song.imagePath != null)
                  _buildInlineMenuItem(
                    AppLocalization.of(
                      context,
                    ).translate("context_menu_reset_image"),
                    CupertinoIcons.refresh,
                    () => _resetImageForSong(song),
                  ),

                _buildInlineMenuItem(
                  AppLocalization.of(context).translate("context_menu_add_fav"),
                  CupertinoIcons.star,
                  () {},
                ),

                _buildInlineMenuItem(
                  AppLocalization.of(context).translate("common_delete"),
                  CupertinoIcons.delete,
                  () => _showDeleteConfirmDialog(song),
                  color: Colors.red,
                  textColor: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineMenuItem(
    String text,
    IconData icon,
    VoidCallback action, {
    Color? color,
    Color? textColor,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        action();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color:
                      textColor ??
                      color ??
                      Theme.of(context).colorScheme.secondary,
                  decoration: TextDecoration.none,
                  fontFamily: 'Arial',
                ),
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
        title: Text(
          AppLocalization.of(context).translate("song_delete_title"),
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontFamily: 'Arial',
          ),
        ),
        content: Text(
          AppLocalization.of(
            context,
          ).translate("song_delete_content").replaceAll("{name}", song.title),
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontFamily: 'Arial',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              AppLocalization.of(context).translate("common_cancel"),
              style: const TextStyle(
                color: CupertinoColors.activeBlue,
                fontFamily: 'Arial',
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(
              AppLocalization.of(context).translate("common_delete"),
              style: const TextStyle(fontFamily: 'Arial'),
            ),
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
    _showInputDialog(
      controller,
      AppLocalization.of(context).translate("common_rename"),
      (text) => _renameSong(song, text),
    );
  }

  void _showArtistDialog(Song song) {
    final controller = TextEditingController(text: song.artist);
    _showInputDialog(
      controller,
      AppLocalization.of(context).translate("context_menu_artist"),
      (text) => _renameArtist(song, text),
    );
  }

  void _showInputDialog(
    TextEditingController controller,
    String title,
    Function(String) onSave,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                  decoration: TextDecoration.none,
                  fontFamily: 'Arial',
                ),
              ),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: controller,
                autofocus: true,
                cursorColor: CupertinoColors.activeBlue,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 16,
                  decoration: TextDecoration.none,
                  fontFamily: 'Arial',
                ),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.2),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Text(
                      AppLocalization.of(context).translate("common_cancel"),
                      style: const TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 17,
                        fontFamily: 'Arial',
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (controller.text.isNotEmpty) {
                        onSave(controller.text);
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(
                      AppLocalization.of(context).translate("common_save"),
                      style: const TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Arial',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          fontFamily: 'Arial',
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
          fontFamily: 'Arial',
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
            child: Container(color: Theme.of(context).scaffoldBackgroundColor),
          ),

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
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              padding: EdgeInsets.only(top: screenHeight * 0.055),
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _songs.isEmpty
                  ? Center(
                    child: Text(
                      AppLocalization.of(context).translate("folder_empty"),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.5),
                        fontFamily: 'Arial',
                      ),
                    ),
                  )
                  : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 30,
                        ),
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];

                      ImageProvider? songImage;
                      if (song.imagePath != null) {
                        if (song.imagePath!.startsWith('http')) {
                          songImage = NetworkImage(song.imagePath!);
                        } else {
                          songImage = FileImage(File(song.imagePath!));
                        }
                      }

                      return GestureDetector(
                        onTapDown:
                            (details) =>
                                _tapPosition = details.globalPosition,
                        onTap: () => _playSong(context, song),
                        onLongPress: () => _showSongContextMenu(song),
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                image:
                                    songImage != null
                                        ? DecorationImage(
                                          image: songImage,
                                          fit: BoxFit.cover,
                                        )
                                        : null,
                              ),
                              child:
                                  song.imagePath == null
                                      ? Icon(
                                        Icons.audiotrack,
                                        size: 45,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                      )
                                      : null,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 80,
                              height: 22,
                              child: _buildGridTextWidget(
                                song.title,
                                TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                  fontFamily: 'Arial',
                                ),
                              ),
                            ),
                            if (song.artist != null)
                              SizedBox(
                                width: 80,
                                height: 18,
                                child: _buildGridTextWidget(
                                  song.artist!,
                                  TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.6),
                                    fontSize: 10,
                                    decoration: TextDecoration.none,
                                    fontFamily: 'Arial',
                                  ),
                                ),
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
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
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
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}