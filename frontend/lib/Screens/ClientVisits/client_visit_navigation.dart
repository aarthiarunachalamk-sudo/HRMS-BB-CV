import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'client_visit_models.dart';

const _locationChannel = MethodChannel('hrms/location');

Future<bool> openClientVisitNavigation(ClientVisit visit) async {
  final latitude = visit.clientLatitude;
  final longitude = visit.clientLongitude;
  final hasCoordinates =
      latitude != null &&
      longitude != null &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);
  final address = visit.address.trim();

  if (!hasCoordinates && address.isEmpty) return false;

  if (Platform.isAndroid) {
    try {
      final opened = await _locationChannel
          .invokeMethod<bool>('openDirectionsChooser', <String, Object?>{
            if (hasCoordinates) 'latitude': latitude,
            if (hasCoordinates) 'longitude': longitude,
            'address': address,
            'label': visit.clientName.trim(),
          });
      if (opened == true) return true;
    } on PlatformException {
      // Fall through to the browser-compatible directions URL.
    }
  }

  final destination = hasCoordinates ? '$latitude,$longitude' : address;
  return launchUrl(
    Uri.https('www.google.com', '/maps/dir/', <String, String>{
      'api': '1',
      'destination': destination,
      'travelmode': _travelMode(visit.travelMode),
    }),
    mode: LaunchMode.externalApplication,
  );
}

String _travelMode(String value) => switch (value.trim().toLowerCase()) {
  'walk' || 'walking' => 'walking',
  'bike' || 'bicycle' || 'bicycling' || 'two wheeler' => 'bicycling',
  _ => 'driving',
};
