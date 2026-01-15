import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mp3/main.dart';
import 'package:mp3/services/LocationServices.dart';
import 'package:mp3/services/WeatherServices.dart';

class ContextService {
  static List<Folder> getAllSpecialFolders() {
    return [
      Folder(name: "Pioggia", isSpecial: true),
      Folder(name: "Soleggiato", isSpecial: true),
      Folder(name: "Musica in Viaggio", isSpecial: true),
      Folder(name: "Studio", isSpecial: true),
      Folder(name: "Relax", isSpecial: true),
      Folder(name: "Giorno", isSpecial: true),
      Folder(name: "Pomeriggio", isSpecial: true),
      Folder(name: "Sera", isSpecial: true),
      Folder(name: "Allenamento", isSpecial: true),
    ];
  }

  //Analizza sensori e dati per attivare le cartelle
  static Future<List<Folder>> getActiveSpecialFolders() async {
    List<Folder> activeFolders = [];
    final DateTime now = DateTime.now();

    // Gestione orario
    if (now.hour >= 7 && now.hour < 13) {
      activeFolders.add(Folder(name: "Giorno", isSpecial: true));
    } else if (now.hour >= 13 && now.hour < 18) {
      activeFolders.add(Folder(name: "Pomeriggio", isSpecial: true));
    } else {
      activeFolders.add(Folder(name: "Sera", isSpecial: true));
      // Relax si attiva spesso la sera
      activeFolders.add(Folder(name: "Relax", isSpecial: true));
    }

    // Posizione reale
    Position? position;
    try {
      if (await LocationService.checkPermissions()) {
        // Timeout breve per non bloccare l'app se il GPS è lento
        position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      debugPrint("Errore recupero posizione ContextService: $e");
    }

    if (position != null) {
      // Velocità di viaggio
      if (position.speed * 3.6 > 20) {
        activeFolders.add(Folder(name: "Musica in Viaggio", isSpecial: true));
      }

      // Meteo reale
      try {
        final weatherData = await WeatherService.getCurrentWeather(
          position.latitude,
          position.longitude,
        );

        if (weatherData != null) {
          if (WeatherService.isRaining(weatherData)) {
            activeFolders.add(Folder(name: "Pioggia", isSpecial: true));
          } else if (WeatherService.isSunnyAndWarm(weatherData)) {
            activeFolders.add(Folder(name: "Soleggiato", isSpecial: true));
          }
        }
      } catch (e) {
        debugPrint("Errore Context Meteo: $e");
      }

      // Luoghi. Cerca di capire dove siamo (scuola, palestra, ecc.) analizzando l'indirizzo
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;

          String placeInfo =
          "${place.name} ${place.street} ${place.subLocality} ${place.thoroughfare}"
              .toLowerCase();

          // Keyword per palestra
          bool isGym = _containsAny(placeInfo, [
            "palestra", "gym", "sport", "fitness", "crossfit",
            "gimnasio", "deportes",
            "fitnessstudio", "sporthalle", "turnhalle",
            "salle de sport", "gymnase",
            "ジム", "体育館", "フィットネス"
          ]);

          if (isGym) {
            activeFolders.add(Folder(name: "Allenamento", isSpecial: true));
          }

          // Keyword per studio
          bool isStudy = _containsAny(placeInfo, [
            "scuola",
            "school",
            "universit",
            "academy",
            "liceo",
            "istituto",
            "biblioteca",
            "library",
            "escuela", "colegio", "universidad",
            "schule", "universität", "bibliothek",
            "école", "lycée", "université", "bibliothèque",
            "学校", "大学", "図書館"
          ]);

          if (isStudy) {
            activeFolders.add(Folder(name: "Studio", isSpecial: true));
          }
        }
      } catch (e) {
        debugPrint("Errore Context Geocoding: $e");
      }
    }

    // Rimuovi duplicati (se una cartella viene attivata da più condizioni)
    final uniqueNames = <String>{};
    final uniqueFolders = <Folder>[];
    for (var folder in activeFolders) {
      if (uniqueNames.add(folder.name)) {
        uniqueFolders.add(folder);
      }
    }

    // Ordine alfabetico per pulizia nel carousel
    uniqueFolders.sort((a, b) => a.name.compareTo(b.name));

    return uniqueFolders;
  }

  // Helper per controllare se una stringa contiene una delle keyword
  static bool _containsAny(String text, List<String> keywords) {
    for (var keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }
}