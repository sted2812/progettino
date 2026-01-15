import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalization {
  final Locale locale;
  AppLocalization(this.locale);

  static const LocalizationsDelegate<AppLocalization> delegate =
      _AppLocalizationDelegate();

  // FIX: Rimosso 'late' e inizializzata a mappa vuota per evitare crash se load() non viene chiamato
  Map<String, String> _localizedStrings = {};

  static AppLocalization of(BuildContext context) {
    // Utilizziamo un cast sicuro o un fallback per evitare null
    return Localizations.of<AppLocalization>(context, AppLocalization) ?? 
           AppLocalization(const Locale('en')); 
  }

  Future<bool> load() async {
    try {
      // Carica il file JSON corrispondente alla lingua
      String jsonString = await rootBundle.loadString(
        'lib/localizescion/${locale.languageCode}.json',
      );
      
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
      return true;
    } catch (e) {
      debugPrint("Errore caricamento lingua: $e");
      _localizedStrings = {}; // Inizializza vuoto per sicurezza
      return false;
    }
  }

  // FIX: Metodo sicuro che non crasha se la chiave non esiste
  String translate(String key) {
    // Se la chiave non esiste nella mappa, restituisce la chiave stessa come fallback
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationDelegate
    extends LocalizationsDelegate<AppLocalization> {
  const _AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    // Supporto per tutte le lingue richieste
    return ['it', 'en', 'es', 'de', 'fr', 'ja'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    AppLocalization localizations = AppLocalization(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationDelegate old) => false;
}