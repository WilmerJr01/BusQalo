import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RutasFavoritasPage extends StatefulWidget {
  const RutasFavoritasPage({Key? key}) : super(key: key);

  @override
  State<RutasFavoritasPage> createState() => _RutasFavoritasPageState();
}

class _RutasFavoritasPageState extends State<RutasFavoritasPage> {
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
    }
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
      appBar: AppBar(title: const Text('Rutas Favoritas')),
      body: user == null
          ? const Center(child: Text('Inicia sesión para ver tus favoritos'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('favoritos')
                  .doc(user!.uid)
                  .collection('lista')
                  .snapshots(),
              builder: (context, favSnapshot) {
                if (favSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!favSnapshot.hasData || favSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No tienes rutas favoritas.'),
                  );
                }

                final favoritos = favSnapshot.data!.docs;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rutas')
                      .snapshots(),
                  builder: (context, rutasSnapshot) {
                    if (!rutasSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rutas = rutasSnapshot.data!.docs;
                    final rutasFavoritas = rutas
                        .where(
                          (ruta) => favoritos.any((fav) => fav.id == ruta.id),
                        )
                        .toList();

                    if (rutasFavoritas.isEmpty) {
                      return const Center(
                        child: Text('No tienes rutas favoritas.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: rutasFavoritas.length,
                      itemBuilder: (context, index) {
                        final ruta = rutasFavoritas[index];
                        final data = ruta.data() as Map<String, dynamic>;
                        final rutaId = ruta.id;
                        final nombre = data['nombre'] ?? 'Ruta sin nombre';
                        final horaInicio = data['horaInicio'] ?? '--:--';
                        final horaFin = data['horaFin'] ?? '--:--';
                        final paradas = List.from(data['puntos'] ?? []);
                        final buses = List.from(data['buses'] ?? []);

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
                                          icon: const Icon(
                                            Icons.favorite,
                                            color: Colors.red,
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
                                            buses.isNotEmpty
                                                ? 'Buses asignados: ${buses.join(', ')}'
                                                : 'Sin buses asignados',
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
            ),
    );
  }
}
