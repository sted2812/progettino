import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mp3/main.dart';
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
  int _selectedPickerIndex = 0;

  static final List<Folder> _userFolders = [];

  static final Set<int> _favoriteFolderIds = {};
  static bool _sortFavoritesFirst = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadInitialData) {
      _loadData();
      _didLoadInitialData = true;
    }
  }

  void _loadData() {
    setState(() {
      _folders = [];

      if (widget.preloadedFolders != null) {
        _folders = List.from(widget.preloadedFolders!);
      } else {
        _folders.add(Folder(
          id: -1,
          name: AppLocalization.of(context).translate("folder_smart_playlists"),
          isSpecial: true,
        ));

        _folders.addAll(_userFolders);
      }

      _applySort();
      _isLoading = false;
    });
  }

  void _applySort() {
    if (widget.preloadedFolders != null) return;

    List<Folder> special = _folders.where((f) => f.id == -1).toList();
    List<Folder> others = _folders.where((f) => f.id != -1).toList();

    int compare(Folder a, Folder b) {
      switch (_currentSort) {
        case SortType.alfabetico:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortType.alfabeticoInverso:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case SortType.dataInserimento:
          return a.id.compareTo(b.id);
        case SortType.casuale:
          return 0;
      }
    }

    if (_currentSort == SortType.casuale) {
      others.shuffle();
    } else {
      others.sort(compare);
    }

    if (_sortFavoritesFirst) {
      others.sort((a, b) {
        bool isAFav = _favoriteFolderIds.contains(a.id);
        bool isBFav = _favoriteFolderIds.contains(b.id);
        if (isAFav && !isBFav) return -1;
        if (!isAFav && isBFav) return 1;
        return 0;
      });
    }

    setState(() {
      _folders = [...special, ...others];
    });
  }

  void _sortFolders(SortType sortType) {
    setState(() {
      _currentSort = sortType;
      _applySort();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalization.of(context).translate("sort_updated_msg")),
          duration: const Duration(seconds: 1)
      ),
    );
  }

  void _changeTheme(ThemeOption option) {
    themeNotifier.value = option;
  }

  void _pickMp3File() {
    if (_userFolders.isEmpty) return;
    _selectedPickerIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Material(
        color: Colors.transparent,
        child: Container(
          height: 320,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text(AppLocalization.of(context).translate("common_cancel"), style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        AppLocalization.of(context).translate("folder_add_mp3_global_title"),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.secondary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text(AppLocalization.of(context).translate("common_confirm"), style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          final folder = _userFolders[_selectedPickerIndex];
                          _pickMp3ForFolder(folder);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 40.0,
                    backgroundColor: Colors.transparent,
                    selectionOverlay: Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue.withOpacity(0.12),
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: CupertinoColors.activeBlue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    onSelectedItemChanged: (int selectedItem) {
                      setState(() {
                        _selectedPickerIndex = selectedItem;
                      });
                    },
                    children: List<Widget>.generate(_userFolders.length, (int index) {
                      return Center(
                        child: Text(
                          _userFolders[index].name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 20,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickMp3ForFolder(Folder folder) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          AppLocalization.of(context).translate("picker_select_mp3_title").replaceAll("{name}", folder.name),
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
        message: Text(AppLocalization.of(context).translate("picker_select_mp3_msg")),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: Text(AppLocalization.of(context).translate("picker_choose_file"), style: const TextStyle(color: CupertinoColors.activeBlue)),
            onPressed: () async {
              Navigator.pop(context);
              final songData = await MusicService.pickSongFromDevice();
              if (songData != null) {
                await MusicService.addSong(songData['title']!, songData['artist']!, folder.name, songData['filePath']!);
              }
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(AppLocalization.of(context).translate("common_cancel"), style: const TextStyle(color: Colors.redAccent)),
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _changeLanguage() {}

  void _showCreateFolderDialog() {
    final TextEditingController nameController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalization.of(context).translate("folder_new_title"),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
                  controller: nameController,
                  placeholder: AppLocalization.of(context).translate("folder_new_placeholder"),
                  placeholderStyle: TextStyle(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                  ),
                  autofocus: true,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                          AppLocalization.of(context).translate("common_cancel"),
                          style: const TextStyle(color: CupertinoColors.activeBlue, fontSize: 17)
                      ),
                    ),
                    Container(width: 1, height: 20, color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
                    GestureDetector(
                      onTap: () {
                        if (nameController.text.isNotEmpty) {
                          setState(() {
                            _userFolders.add(Folder(
                                id: DateTime.now().millisecondsSinceEpoch,
                                name: nameController.text
                            ));
                            _loadData();
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                          AppLocalization.of(context).translate("common_create"),
                          style: const TextStyle(color: CupertinoColors.activeBlue, fontSize: 17, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFolderContextMenu(Folder folder) async {
    if (folder.id == -1) return;

    final bool isFavorite = _favoriteFolderIds.contains(folder.id);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    double left = _tapPosition.dx;
    double top = _tapPosition.dy;
    final screenWidth = MediaQuery.of(context).size.width;
    if (left > screenWidth - 220) left = screenWidth - 220;

    final Color? removeFavColor = (isFavorite && isDarkMode) ? Colors.blue : (isFavorite ? Colors.amber : null);
    final Color? removeFavTextColor = (isFavorite && isDarkMode) ? Colors.blue : null;

    await showMenu<String>(
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
                  child: Text(
                    folder.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),

                _buildInlineMenuItem(
                    folder,
                    AppLocalization.of(context).translate("context_menu_add_mp3"),
                    CupertinoIcons.add,
                        () => _pickMp3ForFolder(folder)
                ),

                if (!folder.isSpecial) ...[
                  _buildInlineMenuItem(
                      folder,
                      AppLocalization.of(context).translate("common_rename"),
                      CupertinoIcons.pencil,
                          () => _showRenameDialog(folder)
                  ),
                  _buildInlineMenuItem(
                      folder,
                      AppLocalization.of(context).translate("context_menu_choose_image"),
                      CupertinoIcons.photo,
                          () => _showImagePickerDialog(folder)
                  ),
                  _buildInlineMenuItem(
                      folder,
                      isFavorite
                          ? AppLocalization.of(context).translate("context_menu_remove_fav")
                          : AppLocalization.of(context).translate("context_menu_add_fav"),
                      isFavorite ? CupertinoIcons.star_slash_fill : CupertinoIcons.star_fill,
                          () {
                        setState(() {
                          if (isFavorite) _favoriteFolderIds.remove(folder.id);
                          else _favoriteFolderIds.add(folder.id);
                          _applySort();
                        });
                      },
                      color: removeFavColor,
                      textColor: removeFavTextColor
                  ),
                  _buildInlineMenuItem(
                      folder,
                      AppLocalization.of(context).translate("common_delete"),
                      CupertinoIcons.delete,
                          () => _showDeleteConfirmDialog(folder),
                      color: Colors.redAccent,
                      textColor: Colors.redAccent
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineMenuItem(Folder folder, String text, IconData icon, VoidCallback action, {Color? color, Color? textColor}) {
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
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Folder folder) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppLocalization.of(context).translate("folder_delete_title"), style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        content: Text(AppLocalization.of(context).translate("folder_delete_content").replaceAll("{name}", folder.name), style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        actions: [
          CupertinoDialogAction(child: Text(AppLocalization.of(context).translate("common_cancel"), style: const TextStyle(color: CupertinoColors.activeBlue)), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(AppLocalization.of(context).translate("common_delete")),
            onPressed: () {
              setState(() {
                _userFolders.removeWhere((f) => f.id == folder.id);
                _favoriteFolderIds.remove(folder.id);
                _loadData();
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(Folder folder) {
    final controller = TextEditingController(text: folder.name);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppLocalization.of(context).translate("common_rename"), style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
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
          CupertinoDialogAction(child: Text(AppLocalization.of(context).translate("common_cancel"), style: const TextStyle(color: CupertinoColors.activeBlue)), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
              child: Text(AppLocalization.of(context).translate("common_save"), style: const TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.bold)),
              onPressed: () {
                setState(() {
                  folder.name = controller.text;
                  _applySort();
                });
                Navigator.pop(ctx);
              }
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog(Folder folder) {}

  IconData _getIconForFolder(String name) {
    switch (name.toLowerCase()) {
      case "pioggia": return CupertinoIcons.umbrella_fill;
      case "soleggiato": return CupertinoIcons.sun_haze_fill;
      case "musica in viaggio": return CupertinoIcons.car_fill;
      case "studio": return CupertinoIcons.book_fill;
      case "relax": return CupertinoIcons.music_house_fill;
      case "giorno": return CupertinoIcons.sun_max;
      case "pomeriggio": return CupertinoIcons.sunset_fill;
      case "sera": return CupertinoIcons.moon_fill;
      case "allenamento": return CupertinoIcons.bolt_fill;
      default: return CupertinoIcons.music_albums_fill;
    }
  }

  Widget _buildFolderNameWidget(String name) {
    const int maxCharsBeforeScroll = 15;
    const double fixedWidth = 90.0;

    if (name.length <= maxCharsBeforeScroll) {
      return Text(
        name,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 12,
          decoration: TextDecoration.none,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return SizedBox(
      width: fixedWidth,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
            stops: [0.0, 0.1, 0.9, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ScrollingText(
          text: " " + name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 12,
            decoration: TextDecoration.none,
          ),
          duration: Duration(seconds: 4 + (name.length ~/ 5)),
          scrollExtent: 30.0,
        ),
      ),
    );
  }

  Widget _buildFolderItem(Folder folder) {
    const double itemWidth = 90.0;

    IconData displayIcon = CupertinoIcons.music_albums_fill;
    if (folder.id == -1) {
      displayIcon = CupertinoIcons.sparkles;
    } else if (folder.isSpecial) {
      displayIcon = _getIconForFolder(folder.name);
    }

    final bool isFavorite = _favoriteFolderIds.contains(folder.id);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color toggleStarColor = isDarkMode ? Colors.blue : Colors.amber;
    final Color borderColor = isFavorite ? toggleStarColor : Theme.of(context).colorScheme.secondary.withOpacity(0.1);
    final double borderWidth = 1.0;

    return GestureDetector(
      onTapDown: (details) => _tapPosition = details.globalPosition,
      onTap: () async {
        if (folder.id == -1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Folderpage(
                pageTitle: AppLocalization.of(context).translate("folder_smart_playlists"),
                preloadedFolders: ContextService.getAllSpecialFolders(),
              ),
            ),
          );
        } else {
          final songs = await MusicService.getSongsInFolder(folder.name);
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SongsListPage(
                  folderName: folder.name,
                  preloadedSongs: songs,
                ),
              ),
            );
          }
        }
      },
      onLongPress: () {
        if (folder.id != -1 && !folder.isSpecial) {
          _showFolderContextMenu(folder);
        }
      },
      child: Column(
        children: [
          Container(
            height: itemWidth, width: itemWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: borderWidth),
              image: folder.imagePath != null ? DecorationImage(image: NetworkImage(folder.imagePath!), fit: BoxFit.cover) : null,
            ),
            child: folder.imagePath == null ? Icon(displayIcon, size: 55, color: Theme.of(context).colorScheme.secondary) : null,
          ),
          const SizedBox(height: 8),
          SizedBox(width: itemWidth, height: 22, child: _buildFolderNameWidget(folder.name)),
        ],
      ),
    );
  }

  void _toggleFavoritesPriority() {
    setState(() {
      _sortFavoritesFirst = !_sortFavoritesFirst;
      _applySort();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_sortFavoritesFirst ? AppLocalization.of(context).translate("menu_fav_priority_on") : AppLocalization.of(context).translate("menu_fav_priority_off")), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final String displayTitle = widget.pageTitle ?? AppLocalization.of(context).translate("folder_page_title");
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color toggleStarColor = isDarkMode ? Colors.blue : Colors.amber;

    return Stack(
      children: [
        Align(alignment: Alignment.bottomCenter, child: Container(height: screenHeight, width: screenWidth, color: Theme.of(context).colorScheme.primary)),
        Align(alignment: Alignment.bottomCenter, child: Container(height: screenHeight * 0.85, decoration: BoxDecoration(borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)), color: Theme.of(context).scaffoldBackgroundColor), padding: EdgeInsets.only(top: screenHeight * 0.055), child: _isLoading ? const Center(child: CircularProgressIndicator()) : GridView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.70, crossAxisSpacing: 20, mainAxisSpacing: 15), itemCount: _folders.length, itemBuilder: (context, index) => _buildFolderItem(_folders[index])))),
        Positioned(top: screenHeight * 0.08, left: 20, child: Row(children: [if (widget.pageTitle != null) Padding(padding: const EdgeInsets.only(right: 10), child: GestureDetector(onTap: () => Navigator.pop(context), child: Icon(CupertinoIcons.chevron_left, size: 36, color: Theme.of(context).colorScheme.secondary))), Text(displayTitle, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 40, fontWeight: FontWeight.bold, decoration: TextDecoration.none)), if (widget.pageTitle == null) Padding(padding: const EdgeInsets.only(left: 15), child: GestureDetector(onTap: _toggleFavoritesPriority, child: Icon(_sortFavoritesFirst ? CupertinoIcons.star_fill : CupertinoIcons.star, size: 30, color: _sortFavoritesFirst ? toggleStarColor : Theme.of(context).colorScheme.secondary.withOpacity(0.5))))])),
        if (widget.pageTitle == null) Align(alignment: const Alignment(0.90, -0.822), child: CustomAnimatedMenu(onCreateFolder: _showCreateFolderDialog, onPickMp3: _pickMp3File, onSortChange: (sort) => _sortFolders(sort), onThemeChange: (theme) => _changeTheme(theme), onLanguageChange: _changeLanguage)),
        if (widget.pageTitle != null) Positioned(top: screenHeight * 0.0775, right: 10, child: IconButton(icon: Icon(CupertinoIcons.fullscreen_exit, size: 36, color: Theme.of(context).colorScheme.secondary), onPressed: () => Navigator.pop(context))),
      ],
    );
  }
}
