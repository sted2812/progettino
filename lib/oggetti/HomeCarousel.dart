import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rpm/main.dart';
import 'package:rpm/services/MusicServices.dart';
import 'package:rpm/ui/SongsListPage.dart';
import 'package:rpm/localization/AppLocalization.dart';

class HomeCarousel extends StatelessWidget {
  final List<Folder> folders;

  const HomeCarousel({
    super.key,
    required this.folders,
  });

  IconData _getIconForFolder(String name) {
    switch (name.toLowerCase()) {
      case "pioggia": case "smart_rain": return CupertinoIcons.umbrella_fill;
      case "soleggiato": case "smart_sunny": return CupertinoIcons.sun_haze_fill;
      case "musica in viaggio": case "smart_travel": return CupertinoIcons.car_fill;
      case "studio": case "smart_study": return CupertinoIcons.book_fill;
      case "relax": case "smart_relax": return CupertinoIcons.music_house_fill;
      case "giorno": case "smart_day": return CupertinoIcons.sun_max;
      case "pomeriggio": case "smart_afternoon": return CupertinoIcons.sunset_fill;
      case "sera": case "smart_evening": return CupertinoIcons.moon_fill;
      case "allenamento": case "smart_workout": return CupertinoIcons.bolt_fill;
      default: return CupertinoIcons.music_albums_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        
        // Icona di default (usata se non c'è immagine)
        IconData icon;
        if (folder.isSpecial) {
           icon = _getIconForFolder(folder.name);
        } else {
           icon = CupertinoIcons.music_albums_fill;
        }
        
        // Sottotitolo
        String subtitle = AppLocalization.of(context).translate("home_playlist_subtitle");
        if (folder.isSpecial) {
          subtitle = AppLocalization.of(context).translate("home_recommended_subtitle");
        } else if (MusicService.favoriteFolderIds.contains(folder.id)) {
          subtitle = AppLocalization.of(context).translate("home_favorites_subtitle");
        }

        return _buildFolderCard(
          context, 
          folder, 
          iconData: icon,
          subtitle: subtitle,
          isSmart: folder.isSpecial 
        );
      },
    );
  }

  Widget _buildFolderCard(BuildContext context, Folder folder, {required IconData iconData, required String subtitle, bool isSmart = false}) {
    const double itemWidth = 140.0; 
    
    String displayName = AppLocalization.of(context).translate(folder.name);

    // Gestione immagine
    ImageProvider? bgImage;
    if (folder.imagePath != null && folder.imagePath!.isNotEmpty) {
      if (folder.imagePath!.startsWith('http')) {
        bgImage = NetworkImage(folder.imagePath!);
      } else {
        bgImage = FileImage(File(folder.imagePath!));
      }
    }
    
    return GestureDetector(
      onTap: () async {
        final songs = await MusicService.getSongsInFolder(folder.name);
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SongsListPage(
                folderName: displayName, 
                preloadedSongs: songs, 
              ),
            ),
          );
        }
      },
      child: Container(
        width: itemWidth,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 140, 
              width: 140,  
              decoration: BoxDecoration(
                color: folder.imagePath != null 
                    ? Colors.transparent // Se c'è l'immagine, sfondo trasparente
                    : Theme.of(context).colorScheme.surface.withOpacity(0.2), 
                borderRadius: BorderRadius.circular(20),
                border: isSmart 
                    ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.8), width: 1.5)
                    : Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.1), width: 1),
                // Applicazione Immagine
                image: bgImage != null
                    ? DecorationImage(
                        image: bgImage, 
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              // Mostra l'icona solo se non c'è un'immagine di sfondo
              child: folder.imagePath == null 
                  ? Icon(iconData, size: 60, color: Theme.of(context).colorScheme.secondary)
                  : null,
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                fontSize: 11,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}