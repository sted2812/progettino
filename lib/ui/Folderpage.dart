import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mp3/main.dart';
import 'package:mp3/oggetti/FolderFunctions.dart';
import 'package:mp3/ui/SongsListPage.dart';
import 'package:mp3/oggetti/ScrollingText.dart';
import 'package:mp3/oggetti/CustomAnimatedMenu.dart';
import 'package:mp3/services/ContextServices.dart';
import 'package:mp3/services/MusicServices.dart';
import 'package:mp3/localization/AppLocalization.dart';

class Folderpage extends StatefulWidget {
  final List<Folder>? preloadedFolders;
  final String? pageTitle;
  const Folderpage({super.key, this.preloadedFolders, this.pageTitle});
  @override
  State<Folderpage> createState() => _FolderpageState();
}

class _FolderpageState extends State<Folderpage> {
  List<Folder> _folders = [];
  bool _isLoading = true;
  bool _didLoadInitialData = false;
  SortType _currentSort = SortType.dataInserimento;
  Offset _tapPosition = Offset.zero;
  Set<int> _favoriteFolderIds = {};
  static bool _sortFavoritesFirst = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadInitialData) {
      _loadData();
      _didLoadInitialData = true;
    }
  }

  void _loadData() async {
    List<Folder> loadedFolders = [];
    List<Folder> favs = await MusicService.getFavoriteFolders();
    _favoriteFolderIds = favs.map((f) => f.id).toSet();
    if (widget.preloadedFolders != null) {
      loadedFolders = List.from(widget.preloadedFolders!);
    } else {
      loadedFolders.add(
        Folder(id: -1, name: "folder_smart_playlists", isSpecial: true),
      );
      final userFolders = await MusicService.getUserFolders();
      loadedFolders.addAll(userFolders);
    }
    if (mounted) {
      setState(() {
        _folders = FolderFunctions.applySort(
          folders: loadedFolders,
          sortType: _currentSort,
          sortFavoritesFirst: _sortFavoritesFirst,
          favoriteIds: _favoriteFolderIds,
          context: context,
        );
        _isLoading = false;
      });
    }
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppLocalization.of(context).translate("folder_new_title"),
        style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(controller: controller, autofocus: true),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalization.of(context).translate("common_cancel"),
            style: TextStyle(color: CupertinoColors.destructiveRed)),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            child: Text(AppLocalization.of(context).translate("common_create"),
            style: TextStyle(color: CupertinoColors.activeBlue)),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await MusicService.addUserFolder(controller.text);
                _loadData();
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(Folder folder) {
    const double itemWidth = 90.0;
    IconData displayIcon = folder.id == -1
        ? CupertinoIcons.sparkles
        : CupertinoIcons.music_albums_fill;
    final bool isFavorite = _favoriteFolderIds.contains(folder.id);
    final Color borderColor = isFavorite
        ? (Theme.of(context).brightness == Brightness.dark
              ? Colors.blue
              : Colors.amber)
        : Theme.of(context).colorScheme.secondary.withOpacity(0.1);

    return GestureDetector(
      onTapDown: (details) => _tapPosition = details.globalPosition,
      onTap: () async {
        if (folder.id == -1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (c) => Folderpage(
                pageTitle: AppLocalization.of(context).translate(folder.name),
                preloadedFolders: ContextService.getAllSpecialFolders(),
              ),
            ),
          );
        } else {
          final songs = await MusicService.getSongsInFolder(folder.name);
          if (mounted)
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (c) => SongsListPage(
                  folderName: AppLocalization.of(
                    context,
                  ).translate(folder.name),
                  preloadedSongs: songs,
                ),
              ),
            );
        }
      },
      onLongPress: () => FolderFunctions.showFolderContextMenu(
        context: context,
        folder: folder,
        tapPosition: _tapPosition,
        favoriteIds: _favoriteFolderIds,
        onRefresh: _loadData,
      ),
      child: Column(
        children: [
          Container(
            height: itemWidth,
            width: itemWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.0),
              image: folder.imagePath != null
                  ? DecorationImage(
                      image: FileImage(File(folder.imagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: folder.imagePath == null
                ? Icon(
                    displayIcon,
                    size: 55,
                    color: Theme.of(context).colorScheme.secondary,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          _buildFolderNameWidget(folder.name),
        ],
      ),
    );
  }

  Widget _buildFolderNameWidget(String name) {
    String displayName = AppLocalization.of(context).translate(name);
    final textStyle = TextStyle(
      color: Theme.of(context).colorScheme.secondary,
      fontSize: 12,
    );
    if (displayName.length <= 12)
      return Text(
        displayName,
        textAlign: TextAlign.center,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    return SizedBox(
      width: 90,
      child: ScrollingText(
        text: " $displayName",
        style: textStyle,
        duration: Duration(seconds: 4 + (displayName.length ~/ 5)),
        scrollExtent: 30.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Container(
          height: size.height,
          width: size.width,
          color: Theme.of(context).colorScheme.primary,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: size.height * 0.85,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            padding: EdgeInsets.only(top: size.height * 0.055),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 15,
                        ),
                    itemCount: _folders.length,
                    itemBuilder: (context, index) =>
                        _buildFolderItem(_folders[index]),
                  ),
          ),
        ),
        Positioned(
          top: size.height * 0.068,
          left: 20,
          right: widget.pageTitle != null ? 60 : 20,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  widget.pageTitle ??
                      AppLocalization.of(
                        context,
                      ).translate("folder_page_title"),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: widget.pageTitle != null ? 32 : 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.pageTitle == null)
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _sortFavoritesFirst = !_sortFavoritesFirst;
                        _loadData();
                      });
                    },
                    child: Icon(
                      _sortFavoritesFirst
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      size: 30,
                      color: _sortFavoritesFirst
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.blue
                                : Colors.amber)
                          : Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.pageTitle == null)
          Align(
            alignment: const Alignment(0.90, -0.822),
            child: CustomAnimatedMenu(
              onCreateFolder: _showCreateFolderDialog,
              onPickMp3: () async {
                final song = await MusicService.pickSongFromDevice();
                if (song != null) {
                  await MusicService.addSong(
                    song['title']!,
                    song['artist']!,
                    "Tutti i brani",
                    song['filePath']!,
                  );
                  _loadData();
                }
              },
              onSortChange: (s) {
                setState(() {
                  _currentSort = s;
                  _loadData();
                });
              },
              onThemeChange: (o) => MusicService.updateTheme(
                o == ThemeOption.dark ? ThemeMode.dark : ThemeMode.light,
              ),
              onLanguageChange: _loadData,
            ),
          ),
        if (widget.pageTitle != null)
          Positioned(
            top: size.height * 0.0775,
            right: 10,
            child: IconButton(
              icon: Icon(
                CupertinoIcons.fullscreen_exit,
                size: 36,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
      ],
    );
  }
}
