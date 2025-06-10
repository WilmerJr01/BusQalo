import 'dart:async';
import 'package:busqalo/utils/polilynes_routes.dart';
import 'package:busqalo/utils/proximidad_rutas.dart';
import 'package:busqalo/utils/registroDeActividad.dart';
import 'package:busqalo/utils/show_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'sliding_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    hide LatLng;
import 'package:busqalo/utils/map_style.dart';

class HomeBody extends StatefulWidget {
  final String? nombre;
  final String? ciudad;
  final String? correo;
  final String? photoUrl;
  final String? apellido;
  final String? fechaNacimiento;

  final String apiKey = 'AIzaSyBtONMyFef_Ojkwcm0D1xyfdvept7nZk6s';

  const HomeBody({
    super.key,
    this.nombre,
    this.ciudad,
    this.correo,
    this.photoUrl,
    this.apellido,
    this.fechaNacimiento,
  });

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final Completer<GoogleMapController> _controller = Completer();
  final Location _location = Location();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Map<String, Map<String, dynamic>> _infoRutas = {};

  LocationData? currentLocation;
  String? _selectedPlaceName;
  double? _selectedLat;
  double? _selectedLng;
  Timer? _timer;
  Set<Polyline> _todasLasRutas = {};
  Map<String, Map<String, dynamic>> _todaLaInfoRutas = {};
  Timer? _timerBuses;

  final TextEditingController _searchController = TextEditingController();

  late FlutterGooglePlacesSdk places;

  final GlobalKey<SlidingOptionsPanelState> _slidingPanelKey =
      GlobalKey<SlidingOptionsPanelState>();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(0, 0),
    zoom: 2,
  );

  @override
  void initState() {
    super.initState();
    places = FlutterGooglePlacesSdk(widget.apiKey);
    _getLocationAndMoveCamera();
    cargarPolylines();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      cargarPolylines();
      print('Cargando rutas cada minuto...');
    });
    _timerBuses = Timer.periodic(const Duration(seconds: 1), (timer) {
      cargarUbicacionesBuses();
    });
  }

  Future<void> cargarPolylines() async {
    try {
      final resultado = await cargarTodasLasRutasDesdeFirebaseYGoogle(
        apiKey: widget.apiKey,
      );
      _todasLasRutas = resultado['polylines'] as Set<Polyline>;
      _todaLaInfoRutas =
          resultado['infoRutas'] as Map<String, Map<String, dynamic>>;

      setState(() {
        _polylines = _todasLasRutas;
        _infoRutas = _todaLaInfoRutas;
      });
    } catch (e) {
      print('Error cargando rutas: $e');
    }
  }

  Future<void> cargarUbicacionesBuses() async {
    final locationData = await _location.getLocation();
    final LatLng userLatLng = LatLng(
      locationData.latitude!,
      locationData.longitude!,
    );
    final snapshot = await FirebaseFirestore.instance
        .collection('emisiones')
        .get();
    final Set<Marker> busMarkers = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final emitiendo = data['emitiendo'] == true;
      final ubicaciones = data['ubicaciones'] as List<dynamic>?;

      if (emitiendo && ubicaciones != null && ubicaciones.isNotEmpty) {
        final ultimaUbicacion = ubicaciones.last;
        final lat = ultimaUbicacion['latitud'];
        final lng = ultimaUbicacion['longitud'];
        final ruta = ultimaUbicacion['ruta'] ?? 'Ruta desconocida';

        final distancia = Geolocator.distanceBetween(
          userLatLng.latitude,
          userLatLng.longitude,
          lat,
          lng,
        );

        if (distancia <= 200) {
          // Solo si está cerca (ajusta el radio si quieres)
          busMarkers.add(
            Marker(
              markerId: MarkerId('bus_${doc.id}'),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: InfoWindow(title: 'Bus', snippet: 'Ruta: $ruta'),
            ),
          );
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value.startsWith('bus_'));
      _markers.addAll(busMarkers);
    });
  }

  Future<void> restaurarRutasCercanasAlUsuario() async {
    final locationData = await _location.getLocation();
    final LatLng userLatLng = LatLng(
      locationData.latitude!,
      locationData.longitude!,
    );

    final Set<Polyline> rutasCercanas = _todasLasRutas.where((poly) {
      final puntos = poly.points;
      return rutaEstaCercaDelUsuario(puntos, userLatLng, radioMetros: 150);
    }).toSet();

    setState(() {
      _selectedPlaceName = null;
      _selectedLat = null;
      _selectedLng = null;
      _markers.clear();
      _polylines = rutasCercanas;
      _infoRutas = Map.fromEntries(
        _todaLaInfoRutas.entries.where(
          (e) => rutasCercanas.any((p) => p.polylineId.value == e.key),
        ),
      );
    });
  }

  Future<void> _getLocationAndMoveCamera() async {
    // Pedimos permisos
    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) return;
    }

    // Activamos servicio
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    // Obtenemos ubicación
    final locationData = await _location.getLocation();
    if (locationData.latitude == null || locationData.longitude == null) {
      print("❌ Ubicación no válida.");
      return;
    }

    // Forzamos reconstrucción (opcional)
    setState(() {
      currentLocation = locationData;
    });

    // Esperamos a que el controlador esté listo
    final controller = await _controller.future;

    // Movemos cámara
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
          zoom: 15,
        ),
      ),
    );
  }

  void _goToMyLocation() async {
    final locationData = await _location.getLocation();
    final controller = await _controller.future;

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
          zoom: 15,
        ),
      ),
    );
  }

  List<AutocompletePrediction> _suggestions = [];

  void _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final predictions = await places.findAutocompletePredictions(
      value,
      countries: ['CO'],
    );
    setState(() {
      _suggestions = predictions.predictions;
    });
  }

  void _onSuggestionTap(AutocompletePrediction prediction) async {
    final placeId = prediction.placeId;
    final place = await places.fetchPlace(
      placeId,
      fields: [PlaceField.Name, PlaceField.Location],
    );
    final lat = place.place?.latLng?.lat;
    final lng = place.place?.latLng?.lng;
    final name = place.place?.name;

    if (lat == null || lng == null) return;

    setState(() {
      _searchController.text = prediction.fullText;
      _suggestions = [];
      _selectedPlaceName = name;
      _selectedLat = lat;
      _selectedLng = lng;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_place'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: name),
        ),
      };
    });

    _slidingPanelKey.currentState?.minimizePanel();

    final LatLng destino = LatLng(lat, lng);

    // 📍 Mi ubicación actual
    final locationData = await _location.getLocation();
    final LatLng miUbicacion = LatLng(
      locationData.latitude!,
      locationData.longitude!,
    );

    final rutas = _todasLasRutas;
    final infoRutas = _todaLaInfoRutas;

    // 🔍 1. Rutas que pasan cerca de mí
    final rutasCercaDeMi = rutas.where((poly) {
      return rutaEstaCercaDelUsuario(
        poly.points,
        miUbicacion,
        radioMetros: 200,
      );
    }).toSet();

    // 🔍 2. Rutas que pasan cerca del destino
    final rutasCercaDelDestino = rutas.where((poly) {
      return rutaEstaCercaDelUsuario(poly.points, destino, radioMetros: 200);
    }).toSet();

    // 🤝 3. Rutas que cumplen ambos criterios
    final rutasConectadas = rutasCercaDeMi.intersection(rutasCercaDelDestino);

    setState(() {
      _polylines = rutasConectadas;
      _infoRutas = Map.fromEntries(
        infoRutas.entries.where(
          (e) => rutasConectadas.any((p) => p.polylineId.value == e.key),
        ),
      );
    });

    // 🎯 Mueve la cámara al destino
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(destino, 17));

    RegistroDeActividad.registrarActividad(
      'Buscó rutas conectadas desde su ubicación a $name',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) async {
              controller.setMapStyle(mapStyle);
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
              _getLocationAndMoveCamera();
            },
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
            onTap: (_) async {
              final locationData = await _location.getLocation();
              final LatLng userLatLng = LatLng(
                locationData.latitude!,
                locationData.longitude!,
              );
              final Set<Polyline> rutasCercanas = _todasLasRutas.where((poly) {
                final puntos = poly.points;
                return rutaEstaCercaDelUsuario(
                  puntos,
                  userLatLng,
                  radioMetros: 200,
                );
              }).toSet();
              setState(() {
                _selectedPlaceName = null;
                _selectedLat = null;
                _selectedLng = null;
                _markers.clear();
                _polylines = rutasCercanas;
                _infoRutas = Map.fromEntries(
                  _todaLaInfoRutas.entries.where(
                    (e) =>
                        rutasCercanas.any((p) => p.polylineId.value == e.key),
                  ),
                );
              });
            },
          ),
          if (_selectedPlaceName != null &&
              _selectedLat != null &&
              _selectedLng != null)
            Positioned(
              top: 350,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _selectedPlaceName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 110,
            right: 10,
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 10,
            child: ShowRoutesCard(polylines: _polylines, infoRutas: _infoRutas),
          ),
          SlidingOptionsPanel(
            key: _slidingPanelKey,
            searchController: _searchController,
            suggestions: _suggestions,
            onSearchChanged: _onSearchChanged,
            onSuggestionTap: _onSuggestionTap,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerBuses?.cancel();
    super.dispose();
  }
}
