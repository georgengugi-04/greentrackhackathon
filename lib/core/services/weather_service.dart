// Live weather for the farm's plot, used to power the dashboard weather
// card and the irrigation advisor. Backed by Open-Meteo (open data,
// no API key required) — https://open-meteo.com
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherSnapshot {
  final double tempC;
  final double humidityPct;
  final double windKph;
  final double rainfallLast24hMm; // actual rain that already fell
  final double rainForecastNext24hMm; // rain expected in the next day
  final int weatherCode; // WMO code, used to pick condition/emoji
  final DateTime fetchedAt;

  const WeatherSnapshot({
    required this.tempC,
    required this.humidityPct,
    required this.windKph,
    required this.rainfallLast24hMm,
    required this.rainForecastNext24hMm,
    required this.weatherCode,
    required this.fetchedAt,
  });

  /// Human label for the WMO weather code (simplified set).
  String get condition {
    if (weatherCode == 0) return 'Clear sky';
    if (weatherCode <= 2) return 'Partly Cloudy';
    if (weatherCode == 3) return 'Overcast';
    if (weatherCode >= 45 && weatherCode <= 48) return 'Foggy';
    if (weatherCode >= 51 && weatherCode <= 67) return 'Drizzle/Rain';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snow';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain showers';
    if (weatherCode >= 95) return 'Thunderstorm';
    return 'Mixed conditions';
  }

  String get emoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 2) return '⛅';
    if (weatherCode == 3) return '☁️';
    if (weatherCode >= 45 && weatherCode <= 48) return '🌫️';
    if (weatherCode >= 51 && weatherCode <= 67) return '🌦️';
    if (weatherCode >= 71 && weatherCode <= 77) return '🌨️';
    if (weatherCode >= 80 && weatherCode <= 82) return '🌧️';
    if (weatherCode >= 95) return '⛈️';
    return '🌤️';
  }
}

class WeatherService {
  Future<WeatherSnapshot> fetchCurrent({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lng'
      '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code'
      '&daily=precipitation_sum'
      '&past_days=1&forecast_days=2&timezone=auto',
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Weather lookup failed (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    final precipDaily = (daily['precipitation_sum'] as List<dynamic>)
        .map((e) => (e as num?)?.toDouble() ?? 0.0)
        .toList();

    // past_days=1, forecast_days=2 -> index 0 = yesterday, 1 = today, 2 = tomorrow
    final rainLast24h = precipDaily.isNotEmpty ? precipDaily[0] : 0.0;
    final rainNext24h = precipDaily.length > 2 ? precipDaily[2] : 0.0;

    return WeatherSnapshot(
      tempC: (current['temperature_2m'] as num).toDouble(),
      humidityPct: (current['relative_humidity_2m'] as num).toDouble(),
      windKph: (current['wind_speed_10m'] as num).toDouble(),
      rainfallLast24hMm: rainLast24h,
      rainForecastNext24hMm: rainNext24h,
      weatherCode: (current['weather_code'] as num).toInt(),
      fetchedAt: DateTime.now(),
    );
  }
}
