import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleDirectionsService {
  final String apiKey;

  GoogleDirectionsService({required this.apiKey});

  /// Ruta simple entre dos puntos
  Future<List<LatLng>> obtenerRuta(LatLng origen, LatLng destino) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origen.latitude},${origen.longitude}&destination=${destino.latitude},${destino.longitude}&mode=driving&key=$apiKey',
    );

    final respuesta = await http.get(url);
    final datos = jsonDecode(respuesta.body);

    if (datos['status'] == 'OK') {
      final puntosCodificados =
          datos['routes'][0]['overview_polyline']['points'];
      return _decodificarPoly(puntosCodificados);
    } else {
      throw Exception('Error obteniendo la ruta: ${datos['status']}');
    }
  }

  /// Ruta con múltiples puntos (waypoints)
  Future<List<LatLng>> obtenerRutaConWaypoints(List<LatLng> puntos) async {
    if (puntos.length < 2) {
      throw Exception('Se necesitan al menos dos puntos para trazar la ruta.');
    }

    final origen = puntos.first;
    final destino = puntos.last;
    final waypoints = puntos.sublist(1, puntos.length - 1);

    final waypointsStr = waypoints
        .map((p) => '${p.latitude},${p.longitude}')
        .join('|');

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origen.latitude},${origen.longitude}&destination=${destino.latitude},${destino.longitude}&waypoints=$waypointsStr&mode=driving&key=$apiKey',
    );

    final respuesta = await http.get(url);
    final datos = jsonDecode(respuesta.body);

    if (datos['status'] == 'OK') {
      final puntosCodificados =
          datos['routes'][0]['overview_polyline']['points'];
      return _decodificarPoly(puntosCodificados);
    } else {
      throw Exception(
        'Error obteniendo ruta con waypoints: ${datos['status']}',
      );
    }
  }

  /// Decodifica el polyline de Google
  List<LatLng> _decodificarPoly(String encoded) {
    List<LatLng> puntos = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      puntos.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return puntos;
  }
}
