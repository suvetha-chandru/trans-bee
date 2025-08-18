@JS()
library;

import 'package:js/js.dart';

@JS('getBrowserPosition')
external dynamic _getBrowserPosition();

Future<Map<String, double>> getBrowserPosition() async {
  final position = await _getBrowserPosition();
  return {
    'latitude': position['latitude'],
    'longitude': position['longitude']
  };
}