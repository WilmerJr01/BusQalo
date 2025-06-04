import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

bool rutaEstaCercaDelUsuario(List<LatLng> ruta, LatLng userLocation, {double radioMetros = 100}) {
  // Verifica distancia a cada segmento interpolando puntos
  for (int i = 0; i < ruta.length - 1; i++) {
    final puntoA = ruta[i];
    final puntoB = ruta[i + 1];

    // Divide el segmento en 10 puntos intermedios
    for (int j = 0; j <= 10; j++) {
      double lat = puntoA.latitude + (puntoB.latitude - puntoA.latitude) * (j / 10);
      double lng = puntoA.longitude + (puntoB.longitude - puntoA.longitude) * (j / 10);
      double distancia = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        lat,
        lng,
      );
      if (distancia <= radioMetros) return true;
    }
  }

  // Verifica distancia a cada punto
  for (final punto in ruta) {
    double distancia = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      punto.latitude,
      punto.longitude,
    );
    if (distancia <= radioMetros) return true;
  }

  return false;
}