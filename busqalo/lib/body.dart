import 'dart:async';
import 'package:busqalo/utils/polilynes_routes.dart';
import 'package:busqalo/utils/proximidad_rutas.dart';
import 'package:busqalo/utils/show_routes.dart';

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

  String? _selectedPlaceName;
  double? _selectedLat;
  double? _selectedLng;
  Timer? _timer;

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
    cargarPolylines();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      cargarPolylines();
      print('Cargando rutas cada minuto...');
    });
    _getLocationAndMoveCamera();
  }

  Future<void> cargarPolylines() async {
    try {
      final resultado = await cargarTodasLasRutasDesdeFirebaseYGoogle(
        apiKey: widget.apiKey,
      );
      setState(() {
        _polylines = resultado['polylines'] as Set<Polyline>;
        _infoRutas =
            resultado['infoRutas'] as Map<String, Map<String, dynamic>>;
      });
    } catch (e) {
      print('Error cargando rutas: $e');
    }
  }

  Future<void> restaurarRutasCercanasAlUsuario() async {
    final locationData = await _location.getLocation();
    final LatLng userLatLng = LatLng(
      locationData.latitude!,
      locationData.longitude!,
    );

    final resultado = await cargarTodasLasRutasDesdeFirebaseYGoogle(
      apiKey: widget.apiKey,
    );
    final Set<Polyline> todasLasPolylines =
        resultado['polylines'] as Set<Polyline>;
    final Map<String, Map<String, dynamic>> infoRutas =
        resultado['infoRutas'] as Map<String, Map<String, dynamic>>;

    final Set<Polyline> rutasCercanas = todasLasPolylines.where((poly) {
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
        infoRutas.entries.where(
          (e) => rutasCercanas.any((p) => p.polylineId.value == e.key),
        ),
      );
    });
  }

  Future<void> _getLocationAndMoveCamera() async {
    final hasPermission = await _location.hasPermission();
    if (hasPermission == PermissionStatus.denied) {
      await _location.requestPermission();
    }

    final serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      await _location.requestService();
    }

    final locationData = await _location.getLocation();

    setState(() {});

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

    setState(() {
      _searchController.text = prediction.fullText;
      _suggestions = [];
      _selectedPlaceName = name;
      _selectedLat = lat;
      _selectedLng = lng;
      _markers = {};
      if (lat != null && lng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_place'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: name),
          ),
        );
      }
    });

    // Minimiza el panel
    _slidingPanelKey.currentState?.minimizePanel();

    if (lat != null && lng != null) {
      // 1. Carga todas las rutas
      final resultado = await cargarTodasLasRutasDesdeFirebaseYGoogle(
        apiKey: widget.apiKey,
      );
      final Set<Polyline> todasLasPolylines =
          resultado['polylines'] as Set<Polyline>;
      final Map<String, Map<String, dynamic>> infoRutas =
          resultado['infoRutas'] as Map<String, Map<String, dynamic>>;

      // 2. Filtra las rutas cercanas al destino
      final LatLng destino = LatLng(lat, lng);
      final Set<Polyline> rutasCercanas = todasLasPolylines.where((poly) {
        final puntos = poly.points;
        return rutaEstaCercaDelUsuario(puntos, destino, radioMetros: 150);
      }).toSet();

      // 3. Actualiza el estado solo con las rutas cercanas
      setState(() {
        _polylines = rutasCercanas;
        _infoRutas = Map.fromEntries(
          infoRutas.entries.where(
            (e) => rutasCercanas.any((p) => p.polylineId.value == e.key),
          ),
        );
      });

      // 4. Mueve la cámara al destino
      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(destino, 17));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) async {
              controller.setMapStyle(mapStyle);
              _controller.complete(controller);
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

              // Carga todas las rutas
              final resultado = await cargarTodasLasRutasDesdeFirebaseYGoogle(
                apiKey: widget.apiKey,
              );
              final Set<Polyline> todasLasPolylines =
                  resultado['polylines'] as Set<Polyline>;
              final Map<String, Map<String, dynamic>> infoRutas =
                  resultado['infoRutas'] as Map<String, Map<String, dynamic>>;

              // Filtra rutas cercanas al usuario
              final Set<Polyline> rutasCercanas = todasLasPolylines.where((
                poly,
              ) {
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
                  infoRutas.entries.where(
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
              top: 300,
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
                    vertical: 12,
                    horizontal: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPlaceName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Latitud: ${_selectedLat!.toStringAsFixed(6)}'),
                      Text('Longitud: ${_selectedLng!.toStringAsFixed(6)}'),
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
    super.dispose();
  }
}
