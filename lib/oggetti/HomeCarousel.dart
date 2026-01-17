import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mp3/main.dart';
import 'package:mp3/services/MusicServices.dart';
import 'package:mp3/ui/SongsListPage.dart';

class HomeCarousel extends StatelessWidget {
  final List<Folder> folders;
  final Map<String, dynamic> smartRec;

  const HomeCarousel({
    super.key,
    required this.folders,
    required this.smartRec,
  });

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

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        
        // Logica icona
        IconData icon;
        if (folder.isSpecial) {
           icon = _getIconForFolder(folder.name);
        } else {
           icon = CupertinoIcons.music_albums_fill;
        }
        
        // Logica sottotitolo
        String subtitle = "Playlist";
        if (folder.isSpecial) subtitle = "Consigliato"; 
        else if (MusicService.favoriteFolderIds.contains(folder.id)) subtitle = "Preferita"; 

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
    
    return GestureDetector(
      onTap: () async {
        final songs = await MusicService.getSongsInFolder(folder.name);
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SongsListPage(
                folderName: folder.name,
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
                    ? Colors.transparent 
                    : Theme.of(context).colorScheme.surface.withOpacity(0.2), 
                borderRadius: BorderRadius.circular(20),
                border: isSmart 
                    ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.8), width: 1.5)
                    : Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.1), width: 1),
                image: folder.imagePath != null
                    ? DecorationImage(
                        image: NetworkImage(folder.imagePath!), 
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: folder.imagePath == null 
                  ? Icon(iconData, size: 60, color: Theme.of(context).colorScheme.secondary)
                  : null,
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                folder.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}