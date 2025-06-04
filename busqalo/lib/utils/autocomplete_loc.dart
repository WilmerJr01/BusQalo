import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

const String apiKey = "AIzaSyBtONMyFef_Ojkwcm0D1xyfdvept7nZk6s";

class DireccionAutocomplete extends StatefulWidget {
  final Function(String direccion, double lat, double lng) onSeleccion;

  const DireccionAutocomplete({super.key, required this.onSeleccion});

  @override
  State<DireccionAutocomplete> createState() => _DireccionAutocompleteState();
}

class _DireccionAutocompleteState extends State<DireccionAutocomplete> {
  final _controller = TextEditingController();
  final _places = FlutterGooglePlacesSdk(apiKey);
  List<AutocompletePrediction> _sugerencias = [];

  void _buscar(String input) async {
    if (input.isEmpty) {
      setState(() => _sugerencias = []);
      return;
    }

    final response = await _places.findAutocompletePredictions(
      input,
      countries: ['CO'], // Cambia según tu país
    );

    final regiones = ['Barranquilla', 'Puerto Colombia', 'Soledad'];

    if (response.predictions.isNotEmpty) {
      setState(() {
        _sugerencias = response.predictions
            .where((p) => regiones.any((region) => p.fullText.contains(region)))
            .toList();
      });
    }
  }

  Future<void> _seleccionar(AutocompletePrediction prediccion) async {
    final detalle = await _places.fetchPlace(
      prediccion.placeId,
      fields: [PlaceField.Address, PlaceField.Location],
    );

    if (detalle.place != null) {
      final place = detalle.place!;
      final direccion = place.address ?? '';
      final lat = place.latLng?.lat ?? 0.0;
      final lng = place.latLng?.lng ?? 0.0;

      _controller.text = direccion;
      setState(() => _sugerencias = []);

      widget.onSeleccion(direccion, lat, lng);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: "Dirección",
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _buscar,
        ),
        if (_sugerencias.isNotEmpty)
          ..._sugerencias.map(
            (s) =>
                ListTile(title: Text(s.fullText), onTap: () => _seleccionar(s)),
          ),
      ],
    );
  }
}
