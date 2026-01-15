import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WeatherService {
  static const String _apiKey = '8cffb4b8dfd30d85cd8284acdd83891e';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<Map<String, dynamic>?> getCurrentWeather(double lat, double lng) async {
    try {
      final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=it');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        debugPrint("Errore API Meteo: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      debugPrint("Eccezione durante il recupero del meteo: $e");
    }
    return null;
  }

  // Verifica se sta piovendo
  static bool isRaining(Map<String, dynamic>? data) {
    if (data == null) return false;

    try {
      final List weatherList = data['weather'];
      if (weatherList.isNotEmpty) {
        final conditionId = weatherList[0]['id'] as int;
        // Codici < 600 indicano pioggia o temporale
        return conditionId < 600;
      }
    } catch (e) {
      debugPrint("Errore parsing meteo pioggia: $e");
    }
    return false;
  }

  // Verifica se c'è il sole e la temperatura è > 15°C
  static bool isSunnyAndWarm(Map<String, dynamic>? data) {
    if (data == null) return false;

    try {
      final temp = (data['main']['temp'] as num).toDouble();
      final List weatherList = data['weather'];

      if (weatherList.isNotEmpty) {
        final conditionId = weatherList[0]['id'] as int;
        // 800 = Sereno, 801 = Poche nuvole
        return temp > 15.0 && (conditionId == 800 || conditionId == 801);
      }
    } catch (e) {
      debugPrint("Errore parsing meteo sole: $e");
    }
    return false;
  }
}