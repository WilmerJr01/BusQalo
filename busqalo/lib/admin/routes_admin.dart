import 'package:busqalo/utils/autocomplete_loc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class AdminRoutesPage extends StatefulWidget {
  const AdminRoutesPage({super.key});

  @override
  State<AdminRoutesPage> createState() => _AdminRoutesPageState();
}

class _AdminRoutesPageState extends State<AdminRoutesPage> {
  final nombreRutaController = TextEditingController();
  final descripcionRutaController = TextEditingController();

  final nombreParadaController = TextEditingController();
  final latitudParadaController = TextEditingController();
  final longitudParadaController = TextEditingController();

  final TextEditingController paradaSearchController = TextEditingController();
  List<AutocompletePrediction> paradaSuggestions = [];
  String? paradaNombreSeleccionado;
  double? paradaLatSeleccionado;
  double? paradaLngSeleccionado;
  late FlutterGooglePlacesSdk places;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    places = FlutterGooglePlacesSdk(
      'AIzaSyBtONMyFef_Ojkwcm0D1xyfdvept7nZk6s',
    ); // Reemplaza con tu API KEY
  }

  Future<List<QueryDocumentSnapshot>> obtenerBuses() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('buses')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot>> obtenerParadas() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('paradas')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs;
  }

  void _mostrarFormularioRuta({DocumentSnapshot? rutaExistente}) async {
    final List<Map<String, dynamic>> paradasSeleccionadas = [];
    final nombreRutaController = TextEditingController();
    TimeOfDay? horaInicio;
    TimeOfDay? horaFin;

    final busesDocs = await obtenerBuses();
    List<String> busesSeleccionados = [];

    if (rutaExistente != null) {
      final data = rutaExistente.data() as Map<String, dynamic>;
      nombreRutaController.text = data['nombre'] ?? '';
      if (data['horaInicio'] != null) {
        final parts = (data['horaInicio'] as String).split(':');
        horaInicio = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (data['horaFin'] != null) {
        final parts = (data['horaFin'] as String).split(':');
        horaFin = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (data['puntos'] != null) {
        for (var punto in data['puntos']) {
          paradasSeleccionadas.add({
            'lat': punto['lat'],
            'lng': punto['lng'],
            'nombre': punto['nombre'] ?? '',
          });
        }
      }
      if (data['buses'] != null) {
        busesSeleccionados = List<String>.from(data['buses']);
      }
    }

    final paradasDocs = await obtenerParadas();
    final filtroController = TextEditingController();
    List<DocumentSnapshot> paradasFiltradas = List.from(paradasDocs);

    showDialog(
      barrierDismissible: true,
      useSafeArea: true,
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          filtroController.addListener(() {
            final textoFiltro = filtroController.text.toLowerCase();
            setStateDialog(() {
              paradasFiltradas = paradasDocs.where((doc) {
                final nombre =
                    (doc.data() as Map<String, dynamic>)['nombre']
                        ?.toLowerCase() ??
                    '';
                return nombre.contains(textoFiltro);
              }).toList();
            });
          });

          return AlertDialog(
            title: Text(rutaExistente != null ? 'Editar Ruta' : 'Nueva Ruta'),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  TextField(
                    controller: nombreRutaController,
                    autofocus: false,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    contextMenuBuilder:
                        (BuildContext context, EditableTextState state) {
                          // Devolver null = no hay menú contextual
                          return const SizedBox.shrink();
                        },
                    
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la ruta',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: horaInicio ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() => horaInicio = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hora de inicio',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              horaInicio != null
                                  ? horaInicio!.format(context)
                                  : 'Seleccionar',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: horaFin ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() => horaFin = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hora de fin',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              horaFin != null
                                  ? horaFin!.format(context)
                                  : 'Seleccionar',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: filtroController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar parada por nombre',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecciona las paradas para esta ruta:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: paradasFiltradas.length,
                      itemBuilder: (context, index) {
                        final parada =
                            paradasFiltradas[index].data()
                                as Map<String, dynamic>;
                        final lat = parada['latitud'];
                        final lng = parada['longitud'];
                        final yaSeleccionada = paradasSeleccionadas.any(
                          (p) => p['lat'] == lat && p['lng'] == lng,
                        );
                        return CheckboxListTile(
                          value: yaSeleccionada,
                          title: Text(
                            parada['nombre'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onChanged: (selected) {
                            setStateDialog(() {
                              if (selected == true && !yaSeleccionada) {
                                paradasSeleccionadas.add({
                                  'lat': lat,
                                  'lng': lng,
                                  'nombre': parada['nombre'] ?? '',
                                });
                              } else if (selected == false && yaSeleccionada) {
                                paradasSeleccionadas.removeWhere(
                                  (p) => p['lat'] == lat && p['lng'] == lng,
                                );
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(),
                  if (paradasSeleccionadas.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        itemCount: paradasSeleccionadas.length,
                        itemBuilder: (context, index) {
                          final parada = paradasSeleccionadas[index];
                          final nombre = parada['nombre'] ?? '';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color.fromARGB(
                                255,
                                197,
                                183,
                                58,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  Divider(),
                  const Text(
                    'Buses asignados a la ruta:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: busesDocs.length,
                      itemBuilder: (context, index) {
                        final bus =
                            busesDocs[index].data() as Map<String, dynamic>;
                        final busId = busesDocs[index].id;
                        final placa = bus['placa'] ?? '';
                        final tipo = bus['tipo'] ?? '';
                        final yaSeleccionado = busesSeleccionados.contains(
                          busId,
                        );
                        return CheckboxListTile(
                          value: yaSeleccionado,
                          title: Text(
                            'Placa: $placa',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            'Tipo: $tipo',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onChanged: (selected) {
                            setStateDialog(() {
                              if (selected == true && !yaSeleccionado) {
                                busesSeleccionados.add(busId);
                              } else if (selected == false && yaSeleccionado) {
                                busesSeleccionados.remove(busId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final nombre = nombreRutaController.text.trim();
                  if (nombre.isEmpty || horaInicio == null || horaFin == null)
                    return;

                  final data = {
                    'nombre': nombre,
                    'horaInicio':
                        '${horaInicio!.hour.toString().padLeft(2, '0')}:${horaInicio!.minute.toString().padLeft(2, '0')}',
                    'horaFin':
                        '${horaFin!.hour.toString().padLeft(2, '0')}:${horaFin!.minute.toString().padLeft(2, '0')}',
                    'puntos': paradasSeleccionadas,
                    'buses': busesSeleccionados,
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  if (rutaExistente != null) {
                    await FirebaseFirestore.instance
                        .collection('rutas')
                        .doc(rutaExistente.id)
                        .update(data);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('rutas')
                        .add(data);
                  }

                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarFormularioParada({DocumentSnapshot? paradaExistente}) {
    if (paradaExistente == null) {
      paradaNombreSeleccionado = null;
      paradaLatSeleccionado = null;
      paradaLngSeleccionado = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(paradaExistente != null ? 'Editar Parada' : 'Nueva Parada'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DireccionAutocomplete(
                onSeleccion: (direccion, lat, lng) {
                  setState(() {
                    paradaNombreSeleccionado = direccion;
                    paradaLatSeleccionado = lat;
                    paradaLngSeleccionado = lng;
                  });
                },
              ),
              if (paradaNombreSeleccionado != null &&
                  paradaLatSeleccionado != null &&
                  paradaLngSeleccionado != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lugar: $paradaNombreSeleccionado'),
                      Text(
                        'Latitud: ${paradaLatSeleccionado!.toStringAsFixed(6)}',
                      ),
                      Text(
                        'Longitud: ${paradaLngSeleccionado!.toStringAsFixed(6)}',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (paradaNombreSeleccionado == null ||
                  paradaLatSeleccionado == null ||
                  paradaLngSeleccionado == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selecciona un lugar válido')),
                );
                return;
              }

              final query = await FirebaseFirestore.instance
                  .collection('paradas')
                  .where('latitud', isEqualTo: paradaLatSeleccionado)
                  .where('longitud', isEqualTo: paradaLngSeleccionado)
                  .get();

              final existeOtra = query.docs.any(
                (doc) =>
                    paradaExistente == null || doc.id != paradaExistente.id,
              );

              if (existeOtra) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ya existe una parada con esa latitud y longitud',
                    ),
                  ),
                );
                return;
              }

              final data = {
                'nombre': paradaNombreSeleccionado,
                'latitud': paradaLatSeleccionado,
                'longitud': paradaLngSeleccionado,
                'createdAt': FieldValue.serverTimestamp(),
              };

              if (paradaExistente != null) {
                await FirebaseFirestore.instance
                    .collection('paradas')
                    .doc(paradaExistente.id)
                    .update(data);
              } else {
                await FirebaseFirestore.instance
                    .collection('paradas')
                    .add(data);
              }

              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _eliminarRuta(String rutaId) {
    FirebaseFirestore.instance.collection('rutas').doc(rutaId).delete();
  }

  void _eliminarParada(String paradaId) {
    FirebaseFirestore.instance.collection('paradas').doc(paradaId).delete();
  }

  Widget _buildRutasList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rutas')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rutas = snapshot.data!.docs;
        if (rutas.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.route_rounded, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Oops... no hay rutas registradas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          );
        }

        return ListView.builder(
          itemCount: rutas.length,
          itemBuilder: (context, index) {
            final rutaDoc = rutas[index];
            final ruta = rutaDoc.data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.alt_route),
                  title: Text(ruta['nombre']),
                  subtitle: Text(
                    '${ruta['horaInicio']}'
                    ' - ${ruta['horaFin']}\n'
                    '${ruta['puntos']?.length ?? 0} paradas',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _mostrarFormularioRuta(rutaExistente: rutaDoc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarRuta(rutaDoc.id),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildParadasList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('paradas')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final paradas = snapshot.data!.docs;
        if (paradas.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.portable_wifi_off_sharp, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Oops... no hay paradas registradas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          );
        }

        return ListView.builder(
          itemCount: paradas.length,
          itemBuilder: (context, index) {
            final paradaDoc = paradas[index];
            final parada = paradaDoc.data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(parada['nombre']),
                  subtitle: Text(
                    'Lat: ${parada['latitud']} \nLng: ${parada['longitud']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _mostrarFormularioParada(
                          paradaExistente: paradaDoc,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarParada(paradaDoc.id),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutas y Paradas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.alt_route, size: 20),
                  onPressed: () => _mostrarFormularioRuta(),
                  label: const Text('Agregar Ruta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 197, 183, 58),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.location_on, size: 20),
                  onPressed: () => _mostrarFormularioParada(),
                  label: const Text('Agregar Parada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 197, 183, 58),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.alt_route,
                color: _currentPage == 0
                    ? Color.fromARGB(255, 197, 183, 58)
                    : Colors.grey,
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.location_on,
                color: _currentPage == 1
                    ? Color.fromARGB(255, 197, 183, 58)
                    : Colors.grey,
              ),
            ],
          ),
          Expanded(
            // <--- Esto es clave para evitar el error
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [_buildRutasList(), _buildParadasList()],
            ),
          ),
        ],
      ),
    );
  }
}
