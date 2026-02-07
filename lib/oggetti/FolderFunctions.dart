import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mp3/main.dart';
import 'package:mp3/services/MusicServices.dart';
import 'package:mp3/localization/AppLocalization.dart';

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
          return nameB.toLowerCase().compareTo(nameA.toLowerCase());
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
                  _buildAction(
                    context,
                    isFavorite
                        ? "context_menu_remove_fav"
                        : "context_menu_add_fav",
                    isFavorite
                        ? CupertinoIcons.star_slash_fill
                        : CupertinoIcons.star_fill,
                    () async {
                      await MusicService.toggleFolderFavorite(folder.id);
                      onRefresh();
                    },
                    color: isFavorite
                        ? (isDarkMode ? Colors.blue : Colors.amber)
                        : null,
                  ),
                  _buildAction(
                    context,
                    "common_delete",
                    CupertinoIcons.delete,
                    () => _showDeleteDialog(context, folder, onRefresh),
                    color: Colors.redAccent,
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
            Text(
              AppLocalization.of(context).translate(key),
              style: TextStyle(
                fontSize: 15,
                color: color ?? Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showRenameDialog(
    BuildContext context,
    Folder folder,
    VoidCallback onRefresh,
  ) {
    final controller = TextEditingController(text: folder.name);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppLocalization.of(context).translate("common_rename")),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(controller: controller, autofocus: true),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalization.of(context).translate("common_cancel")),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            child: Text(AppLocalization.of(context).translate("common_save")),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final db = await MusicService.database;
                await db.update(
                  'folders',
                  {'name': controller.text},
                  where: 'id = ?',
                  whereArgs: [folder.id],
                );
                onRefresh();
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  static void _showDeleteDialog(
    BuildContext context,
    Folder folder,
    VoidCallback onRefresh,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          AppLocalization.of(context).translate("folder_delete_title"),
        ),
        content: Text(
          AppLocalization.of(context)
              .translate("folder_delete_content")
              .replaceAll("{name}", folder.name),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              AppLocalization.of(context).translate("common_cancel"),
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(
              AppLocalization.of(context).translate("common_delete"),
              style: TextStyle(color: CupertinoColors.activeBlue),
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
}
