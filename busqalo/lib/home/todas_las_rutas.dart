import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TodasLasRutasPage extends StatefulWidget {
  const TodasLasRutasPage({Key? key}) : super(key: key);

  @override
  State<TodasLasRutasPage> createState() => _TodasLasRutasPageState();
}

class _TodasLasRutasPageState extends State<TodasLasRutasPage> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _toggleFavorito(String rutaId) async {
    if (user == null) return;
    final favRef = FirebaseFirestore.instance
        .collection('favoritos')
        .doc(user!.uid)
        .collection('lista')
        .doc(rutaId);

    final favDoc = await favRef.get();
    if (favDoc.exists) {
      await favRef.delete();
    } else {
      await favRef.set({'rutaId': rutaId, 'fecha': Timestamp.now()});
    }
  }

  Future<bool> _esFavorito(String rutaId) async {
    if (user == null) return false;
    final favDoc = await FirebaseFirestore.instance
        .collection('favoritos')
        .doc(user!.uid)
        .collection('lista')
        .doc(rutaId)
        .get();
    return favDoc.exists;
  }

  Future<List<Map<String, dynamic>>> _obtenerInfoBuses(
    List<dynamic> busIds,
  ) async {
    final buses = <Map<String, dynamic>>[];
    for (String busId in busIds) {
      final doc = await FirebaseFirestore.instance
          .collection('buses')
          .doc(busId)
          .get();
      if (doc.exists) {
        buses.add(
          doc.data()!..['id'] = doc.id,
        ); // le añadimos el id por si acaso
      }
    }
    return buses;
  }

  void _mostrarDetalleRuta(BuildContext context, Map<String, dynamic> data) {
    final paradas = List.from(data['puntos'] ?? []);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['nombre'] ?? 'Ruta'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['horaInicio'] != null && data['horaFin'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Horario: ${data['horaInicio']} - ${data['horaFin']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              const Text(
                'Paradas:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...paradas.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final parada = entry.value;
                final nombreParada = parada['nombre'] ?? 'Parada sin nombre';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('$index. $nombreParada'),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todas las rutas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rutas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay rutas disponibles.'));
          }
          final rutas = snapshot.data!.docs;
          return ListView.builder(
            itemCount: rutas.length,
            itemBuilder: (context, index) {
              final data = rutas[index].data() as Map<String, dynamic>;
              final rutaId = rutas[index].id;
              final nombre = data['nombre'] ?? 'Ruta sin nombre';
              return FutureBuilder<bool>(
                future: _esFavorito(rutaId),
                builder: (context, favSnapshot) {
                  final esFavorito = favSnapshot.data ?? false;
                  final horaInicio = data['horaInicio'] ?? '--:--';
                  final horaFin = data['horaFin'] ?? '--:--';
                  final paradas = List.from(data['puntos'] ?? []);
                  final busIds = List<String>.from(data['buses'] ?? []);

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _obtenerInfoBuses(busIds),
                    builder: (context, busSnapshot) {
                      final busesInfo = busSnapshot.data ?? [];

                      final busesTexto = busesInfo.isNotEmpty
                          ? busesInfo
                                .map((b) => '${b['placa']} (${b['tipo']})')
                                .join(', ')
                          : 'Sin buses asignados';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () => _mostrarDetalleRuta(context, data),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// Header: nombre + favorito
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          nombre,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          esFavorito
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: esFavorito
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                        onPressed: () async {
                                          await _toggleFavorito(rutaId);
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  /// Horarios
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 20),
                                      const SizedBox(width: 6),
                                      Text('De $horaInicio a $horaFin'),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  /// Paradas
                                  Row(
                                    children: [
                                      const Icon(Icons.place, size: 20),
                                      const SizedBox(width: 6),
                                      Text('${paradas.length} paradas'),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  /// Buses
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.directions_bus,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Buses asignados: $busesTexto',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
