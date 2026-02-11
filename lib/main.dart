import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:rpm/ui/NavBar.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:rpm/localization/AppLocalization.dart'; 
import 'package:rpm/services/MusicServices.dart';

enum ThemeOption { automatico, light, dark }
enum SortType { dataInserimento, alfabetico, alfabeticoInverso, casuale }
enum LoopMode { none, playlist, single }

final ValueNotifier<Track?> currentTrackNotifier = ValueNotifier(null);
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('it'));

class Track {
  final String title;
  final String folderName;
  final String? artist;
  final int? id;
  final String? imagePath; 
  
  const Track({
    required this.title, 
    required this.folderName, 
    this.artist, 
    this.id,
    this.imagePath,
  });
}

class Song {
  final int id;
  final String title;
  final String? artist; 
  final String folderName;
  final String? filePath;
  final String? imagePath;
  int playCount;

  Song({
    required this.id,
    required this.title, 
    this.artist, 
    required this.folderName,
    this.filePath,
    this.imagePath,
    this.playCount = 0, 
  });
}

class Folder {
  final int id; 
  String name;
  String? imagePath; 
  bool isSpecial;
  SortType mp3SortType;    
  
  Folder({
    this.id = 0, 
    required this.name, 
    this.imagePath, 
    this.isSpecial = false,
    this.mp3SortType = SortType.dataInserimento, 
  });
}

Future<void> updateLanguage(String langCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language_code', langCode);
  localeNotifier.value = Locale(langCode);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('language_code');
    if (langCode != null) {
      localeNotifier.value = Locale(langCode);
    }

    await MusicService.init();
  } catch (e) {
    debugPrint("Error during initialization: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MusicService.themeNotifier,
      builder: (context, currentMode, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, currentLocale, _) {
            return MaterialApp(
              title: 'RPM',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                brightness: Brightness.light,
                scaffoldBackgroundColor: const Color.fromARGB(255, 223, 231, 255),
                colorScheme: const ColorScheme.light(
                  surface: Color.fromARGB(134, 128, 136, 255),
                  primary: Color.fromARGB(255, 198, 214, 255),
                  secondary: Color.fromARGB(255, 19, 19, 19),
                ),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark, 
                scaffoldBackgroundColor: const Color.fromARGB(255, 19, 19, 19),
                colorScheme: const ColorScheme.dark(
                  surface: Color.fromARGB(255, 61, 57, 80),
                  primary: Color.fromARGB(255, 31, 28, 42),
                  secondary: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              themeMode: currentMode,
              locale: currentLocale,
              supportedLocales: const [
                Locale('it'), Locale('en'), Locale('es'), 
                Locale('de'), Locale('fr'), Locale('ja')
              ],
              localizationsDelegates: [
                AppLocalization.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const NavBar(), 
            );
          }
        );
      },
    );
  }
}