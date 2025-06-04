import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:busqalo/utils/google_directions_services.dart';
import 'package:busqalo/utils/proximidad_rutas.dart';

Future<Map<String, dynamic>> cargarTodasLasRutasDesdeFirebaseYGoogle({
  required String apiKey,
}) async {
  final posicion = await Geolocator.getCurrentPosition();
  final userLatLng = LatLng(posicion.latitude, posicion.longitude);

  final querySnapshot = await FirebaseFirestore.instance
      .collection('rutas')
      .get();

  Set<Polyline> polylines = {};
  Map<String, Map<String, dynamic>> infoRutas = {};

  for (var doc in querySnapshot.docs) {
    final data = doc.data();
    final List<dynamic> puntos = data['puntos'];
    final String nombreRuta = data['nombre'] ?? 'Ruta sin nombre';
    final String horaInicio = data['horaInicio'] ?? '';
    final String horaFin = data['horaFin'] ?? '';

    final List<LatLng> coordenadas = puntos.map((p) {
      return LatLng(p['lat'], p['lng']);
    }).toList();

    final service = GoogleDirectionsService(apiKey: apiKey);

    try {
      final rutaDecodificada = await service.obtenerRutaConWaypoints(
        coordenadas,
      );

      if (rutaEstaCercaDelUsuario(
        rutaDecodificada,
        userLatLng,
        radioMetros: 200,
      )) {
        final polyId = 'ruta-${doc.id}';
        polylines.add(
          Polyline(
            polylineId: PolylineId(polyId),
            color: const Color(0xFF1E88E5),
            width: 5,
            points: rutaDecodificada,
          ),
        );
        infoRutas[polyId] = {
          'nombre': nombreRuta,
          'inicio': puntos.isNotEmpty ? puntos.first['nombre'] ?? '' : '',
          'destino': puntos.isNotEmpty ? puntos.last['nombre'] ?? '' : '',
          'horaInicio': horaInicio,
          'horaFin': horaFin,
        };
      }
    } catch (e) {
      print('Error cargando ruta ${doc.id}: $e');
    }
  }

  return {'polylines': polylines, 'infoRutas': infoRutas};
}
