import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalization {
  final Locale locale;
  AppLocalization(this.locale);

  static const LocalizationsDelegate<AppLocalization> delegate =
      _AppLocalizationDelegate();

  Map<String, String> _localizedStrings = {};

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization) ?? 
           AppLocalization(const Locale('en')); 
  }

  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString(
        'lib/localization/${locale.languageCode}.json',
      );
      
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
      return true;
    } catch (e) {
      debugPrint("Errore caricamento lingua: $e");
      _localizedStrings = {};
      return false;
    }
  }

  String translate(String key) {
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