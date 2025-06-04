import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShowRoutesCard extends StatelessWidget {
  final Set<Polyline> polylines;
  final Map<String, Map<String, dynamic>> infoRutas;

  const ShowRoutesCard({
    super.key,
    required this.polylines,
    required this.infoRutas,
  });

  String direccionCorta(String? direccion) {
    if (direccion == null) return '';
    final partes = direccion.split(',');
    if (partes.length >= 2) {
      return '${partes[0].trim()},${partes[1].trim()}, ${partes[2].trim()}';
    }
    return direccion.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rutas cercanas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 0, maxHeight: 200),
              child: polylines.isNotEmpty
                  ? ListView.builder(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      shrinkWrap: true,
                      reverse: false,
                      itemCount: polylines.length,
                      itemBuilder: (context, index) {
                        final poly = polylines.elementAt(index);
                        final info = infoRutas[poly.polylineId.value];
                        if (info == null) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.route,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  info['nombre'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.directions_bus_filled_outlined,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    direccionCorta(info['inicio']),
                                    style: const TextStyle(fontSize: 12),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.directions_bus_filled,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    direccionCorta(info['destino']),
                                    style: const TextStyle(fontSize: 12),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                Text(
                                  'Hora inicio: ${info['horaInicio'] ?? ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_filled,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                Text(
                                  'Hora fin: ${info['horaFin'] ?? ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),

                            const Divider(height: 8),
                          ],
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'No hay rutas cercanas',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
