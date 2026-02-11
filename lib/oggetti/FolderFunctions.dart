import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rpm/main.dart';
import 'package:rpm/services/MusicServices.dart';
import 'package:rpm/localization/AppLocalization.dart';

class FolderFunctions {
  
  static List<Folder> applySort({
    required List<Folder> folders,
    required SortType sortType,
    required bool sortFavoritesFirst,
    required Set<int> favoriteIds,
    required BuildContext context,
  }) {
    List<Folder> special = folders.where((f) => f.id == -1).toList();
    List<Folder> others = folders.where((f) => f.id != -1).toList();

    int compare(Folder a, Folder b) {
      String nameA = AppLocalization.of(context).translate(a.name);
      String nameB = AppLocalization.of(context).translate(b.name);
      switch (sortType) {
        case SortType.alfabetico:
          return nameA.toLowerCase().compareTo(nameB.toLowerCase());
        case SortType.alfabeticoInverso:
          return b.name.toLowerCase().compareTo(nameA.toLowerCase());
        case SortType.dataInserimento:
          return a.id.compareTo(b.id);
        case SortType.casuale:
          return 0;
      }
    }

    if (sortType == SortType.casuale) {
      others.shuffle();
    } else {
      others.sort(compare);
    }

    if (sortFavoritesFirst) {
      others.sort((a, b) {
        bool isAFav = favoriteIds.contains(a.id);
        bool isBFav = favoriteIds.contains(b.id);
        if (isAFav && !isBFav) return -1;
        if (!isAFav && isBFav) return 1;
        return 0;
      });
    }
    return [...special, ...others];
  }

  static void showFolderContextMenu({
    required BuildContext context,
    required Folder folder,
    required Offset tapPosition,
    required Set<int> favoriteIds,
    required VoidCallback onRefresh,
  }) async {
    final bool isFavorite = favoriteIds.contains(folder.id);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    double left = tapPosition.dx;
    double top = tapPosition.dy;
    if (left > MediaQuery.of(context).size.width - 220)
      left = MediaQuery.of(context).size.width - 220;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                        AppLocalization.of(context).translate(folder.name),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.secondary,
                            fontFamily: 'Arial',
                            decoration: TextDecoration.none
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis
                    )
                ),
                _buildAction(
                  context,
                  "context_menu_add_mp3",
                  CupertinoIcons.add,
                  () async {
                    final song = await MusicService.pickSongFromDevice();
                    if (song != null) {
                      await MusicService.addSong(
                        song['title']!,
                        song['artist']!,
                        folder.name,
                        song['filePath']!,
                      );
                      onRefresh();
                    }
                  },
                ),
                if (!folder.isSpecial) ...[
                  _buildAction(
                    context,
                    "common_rename",
                    CupertinoIcons.pencil,
                    () => _showRenameDialog(context, folder, onRefresh),
                  ),
                  _buildAction(
                    context,
                    "context_menu_choose_image",
                    CupertinoIcons.photo,
                    () async {
                      final img = await MusicService.pickImageFromDevice();
                      if (img != null) {
                        await MusicService.updateUserFolderImage(
                          folder.id,
                          img,
                        );
                        onRefresh();
                      }
                    },
                  ),
                  
                  // Opzione Ripristina Immagine (se presente)
                  if (folder.imagePath != null)
                     _buildAction(
                      context,
                      "context_menu_reset_image",
                      CupertinoIcons.refresh,
                      () async {
                        await MusicService.updateUserFolderImage(folder.id, null);
                        onRefresh();
                      },
                    ),

                  _buildAction(
                    context,
                    isFavorite ? "context_menu_remove_fav" : "context_menu_add_fav",
                    isFavorite ? CupertinoIcons.star_slash_fill : CupertinoIcons.star_fill,
                    () async {
                         await MusicService.toggleFolderFavorite(folder.id);
                         onRefresh();
                    },
                    color: removeFavColor,
                    textColor: removeFavTextColor
                  ),
                  _buildAction(
                    context,
                    "common_delete",
                    CupertinoIcons.delete,
                    () => _showDeleteConfirmDialog(context, folder, onRefresh),
                    color: Colors.red,
                    textColor: Colors.red,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildAction(
    BuildContext context,
    String key,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    Color? textColor,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
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
                AppLocalization.of(context).translate(key),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? color ?? Theme.of(context).colorScheme.secondary,
                  fontFamily: 'Arial',
                  decoration: TextDecoration.none
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DIALOGO RINOMINA (Stile SongsListPage)
  static void _showRenameDialog(BuildContext context, Folder folder, VoidCallback onRefresh) {
    final controller = TextEditingController(text: folder.name);
    _showInputDialog(
        context, 
        AppLocalization.of(context).translate("common_rename"), 
        "", 
        controller, 
        (text) async {
            final db = await MusicService.database;
            await db.update('folders', {'name': text}, where: 'id = ?', whereArgs: [folder.id]);
            onRefresh();
        }
    );
  }

  static void showCreateFolderDialog(BuildContext context, VoidCallback onRefresh) {
    final controller = TextEditingController();
    _showInputDialog(
        context, 
        AppLocalization.of(context).translate("folder_new_title"), 
        AppLocalization.of(context).translate("folder_new_placeholder"), 
        controller, 
        (text) async {
            await MusicService.addUserFolder(text);
            onRefresh();
        },
        isCreate: true
    );
  }

  // DIALOGO ELIMINA
  static void _showDeleteConfirmDialog(BuildContext context, Folder folder, VoidCallback onRefresh) {
     showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          AppLocalization.of(context).translate("folder_delete_title"),
          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontFamily: 'Arial'),
        ),
        content: Text(
          AppLocalization.of(context).translate("folder_delete_content").replaceAll("{name}", folder.name),
          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontFamily: 'Arial'),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              AppLocalization.of(context).translate("common_cancel"),
              style: const TextStyle(color: CupertinoColors.activeBlue, fontFamily: 'Arial'),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(
              AppLocalization.of(context).translate("common_delete"),
              style: const TextStyle(fontFamily: 'Arial'),
            ),
            onPressed: () async {
              await MusicService.deleteUserFolder(folder.id);
              onRefresh();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // HELPER DIALOGO INPUT (Stile Unificato)
  static void _showInputDialog(
      BuildContext context, 
      String title, 
      String placeholder, 
      TextEditingController controller, 
      Function(String) onSave,
      {bool isCreate = false}) {
    
    showCupertinoDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
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
              
              // --- STILE INPUT (Copiato da SongsListPage) ---
              Material(
                color: Colors.transparent,
                child: CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder.isNotEmpty ? placeholder : null,
                  placeholderStyle: TextStyle(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                    fontFamily: 'Arial',
                  ),
                  autofocus: true,
                  cursorColor: CupertinoColors.activeBlue, // 1. Cursore Blu
                  autocorrect: false,
                  enableSuggestions: false, // 2. No suggerimenti/sottolineature
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 16,
                    decoration: TextDecoration.none, // 3. No decorazioni
                    fontFamily: 'Arial',
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
                  Container(width: 1, height: 20, color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
                  GestureDetector(
                    onTap: () {
                      if (controller.text.isNotEmpty) {
                        onSave(controller.text);
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(
                      isCreate 
                        ? AppLocalization.of(context).translate("common_create")
                        : AppLocalization.of(context).translate("common_save"),
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
}