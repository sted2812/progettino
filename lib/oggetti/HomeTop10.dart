import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mp3/main.dart';

class HomeTop10 extends StatelessWidget {
  final List<Song> songs;
  final bool isExpanded;
  final VoidCallback onToggleExpansion;
  final VoidCallback onReset;
  final ScrollController scrollController;

  const HomeTop10({
    super.key,
    required this.songs,
    required this.isExpanded,
    required this.onToggleExpansion,
    required this.onReset,
    required this.scrollController,
  });

  void _showResetConfirmDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Azzera Classifica"),
        content: const Text("Vuoi cancellare le statistiche mensili?"),
        actions: [
          CupertinoDialogAction(child: const Text("Annulla"), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Azzera"),
            onPressed: () {
              onReset();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Box principale
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.white.withOpacity(0.05) 
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
        ),
        boxShadow: isExpanded ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ] : [],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          InkWell(
            onTap: onToggleExpansion,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isExpanded ? "Top 10 del mese" : "Top 3 del mese",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isExpanded ? "Visualizza meno" : "Vedi tutte",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Lista Brani
          Expanded(
            child: ListView.separated(
              controller: scrollController, 
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
              physics: isExpanded 
                  ? const BouncingScrollPhysics() 
                  : const NeverScrollableScrollPhysics(),
              itemCount: 11, // 10 brani + 1 tasto reset
              separatorBuilder: (context, index) => Divider(
                indent: 70, 
                endIndent: 20, 
                height: 1,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.05)
              ),
              itemBuilder: (context, index) {
                // Tasto reset
                if (index == 10) {
                  if (!isExpanded) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CupertinoButton(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                      child: const Text("Azzera Classifica", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      onPressed: () => _showResetConfirmDialog(context),
                    ),
                  );
                }

                // Slot vuoto
                if (index >= songs.length) {
                   return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary.withOpacity(0.3), fontSize: 18)),
                        ),
                      ),
                      title: Text("Nessun brano", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.secondary.withOpacity(0.4))),
                      subtitle: Text("-", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary.withOpacity(0.3))),
                   );
                }

                // Slot pieno
                final song = songs[index];
                final int playCount = song.playCount; 
                
                Color borderColor;
                double borderWidth = 0.5;
                // Colori di 1°, 2° e 3° classificato
                if (index == 0) { borderColor = const Color(0xFFFFD700); borderWidth = 2.0; } 
                else if (index == 1) { borderColor = const Color(0xFFC0C0C0); borderWidth = 2.0; } 
                else if (index == 2) { borderColor = const Color(0xFFCD7F32); borderWidth = 2.0; } 
                else { borderColor = Theme.of(context).colorScheme.secondary.withOpacity(0.1); }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: Colors.transparent, 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: borderWidth),
                    ),
                    child: Center(
                      child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary, fontSize: 18)),
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist ?? "Sconosciuto",
                    style: TextStyle(
                      fontSize: 12, 
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.6)
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text("$playCount ascolti", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary.withOpacity(0.7))),
                  onTap: null, 
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}