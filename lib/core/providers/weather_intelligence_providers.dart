import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/weather_station_service.dart';
import '../../data/models/models.dart';

final weatherStationServiceProvider = Provider<WeatherStationService>((_) => WeatherStationService());

final weatherStationInfoProvider = StreamProvider.autoDispose<WeatherStationInfo?>(
    (ref) => ref.read(weatherStationServiceProvider).watchStationInfo());

final weatherDataQualityProvider = FutureProvider.autoDispose<WeatherDataQuality?>(
    (ref) => ref.read(weatherStationServiceProvider).getDataQuality());

final currentWeatherFeaturesProvider = StreamProvider.autoDispose<WeatherFeatures?>(
    (ref) => ref.read(weatherStationServiceProvider).watchCurrentFeatures());

final cropWeatherRiskProvider = StreamProvider.autoDispose.family<CropWeatherRisk?, String>(
    (ref, cropKey) => ref.read(weatherStationServiceProvider).watchCropRisk(cropKey));

final hourlyWeatherHistoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
    (ref, hours) => ref.read(weatherStationServiceProvider).getHourlyHistory(hours: hours));

final dailyWeatherHistoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
    (ref, days) => ref.read(weatherStationServiceProvider).getDailyHistory(days: days));

/// The crop currently selected for the "Today's Farm Intelligence" card.
final selectedIntelligenceCropProvider =
    NotifierProvider.autoDispose<SelectedCropNotifier, String>(SelectedCropNotifier.new);

class SelectedCropNotifier extends Notifier<String> {
  @override
  String build() => 'cabbage';

  set state(String value) => state = value;

  void setCrop(String crop) => state = crop;
}

const kWeatherIntelligenceCrops = {
  'spinach': 'Spinach',
  'cabbage': 'Cabbage',
  'tomato': 'Tomato',
  'coffee': 'Coffee',
  'maize': 'Maize',
  'beans': 'Beans',
};