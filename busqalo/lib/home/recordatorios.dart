import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecordatoriosPage extends StatefulWidget {
  const RecordatoriosPage({Key? key}) : super(key: key);

  @override
  State<RecordatoriosPage> createState() => _RecordatoriosPageState();
}

class _RecordatoriosPageState extends State<RecordatoriosPage> {
  String? _rutaSeleccionada;
  final TextEditingController _mensajeController = TextEditingController();
  TimeOfDay? _horaSeleccionada;
  DateTime? _fechaSeleccionada;

  Future<void> _agregarRecordatorio() async {
    final rutaDoc = await FirebaseFirestore.instance
        .collection('rutas')
        .doc(_rutaSeleccionada)
        .get();
    final nombreRuta = rutaDoc['nombre'] ?? 'Ruta sin nombre';

    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        _rutaSeleccionada == null ||
        _horaSeleccionada == null ||
        _fechaSeleccionada == null)
      return;

    final mensaje = _mensajeController.text.trim();
    if (mensaje.isEmpty) return;

    final recordatorioDateTime = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );

    await FirebaseFirestore.instance
        .collection('recordatorio')
        .doc(user.uid)
        .collection('lista')
        .add({
          'rutaId': _rutaSeleccionada,
          'rutaNombre': nombreRuta,
          'mensaje': mensaje,
          'hora': Timestamp.fromDate(recordatorioDateTime),
          'creado': Timestamp.now(),
        });

    _mensajeController.clear();
    setState(() {
      _rutaSeleccionada = null;
      _horaSeleccionada = null;
      _fechaSeleccionada = null;
    });
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _horaSeleccionada = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Recordatorios')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown de rutas
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rutas')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final rutas = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _rutaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Selecciona una ruta',
                    border: OutlineInputBorder(),
                  ),
                  items: rutas.map((doc) {
                    final nombre = doc['nombre'] ?? 'Sin nombre';
                    return DropdownMenuItem(value: doc.id, child: Text(nombre));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _rutaSeleccionada = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            // Campo de mensaje
            TextField(
              controller: _mensajeController,
              decoration: const InputDecoration(
                labelText: 'Mensaje del recordatorio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Selector de hora
            Row(
              children: [
                Text(
                  _horaSeleccionada == null
                      ? 'Hora no seleccionada'
                      : 'Hora: ${_horaSeleccionada!.format(context)}',
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: const Text('Seleccionar hora'),
                  onPressed: _seleccionarHora,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _fechaSeleccionada == null
                      ? 'Fecha no seleccionada'
                      : 'Fecha: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Seleccionar fecha'),
                  onPressed: _seleccionarFecha,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Botón guardar
            ElevatedButton.icon(
              icon: const Icon(Icons.add_alert),
              label: const Text('Agregar recordatorio'),
              onPressed: _agregarRecordatorio,
            ),
            const SizedBox(height: 24),

            // Lista de recordatorios
            const Text(
              'Tus recordatorios:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: user == null
                  ? const Center(
                      child: Text('Inicia sesión para ver tus recordatorios'),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('recordatorio')
                          .doc(user.uid)
                          .collection('lista')
                          .orderBy('creado', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text('No tienes recordatorios aún.'),
                          );
                        }
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final DateTime? hora = (data['hora'] as Timestamp?)
                                ?.toDate();
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.alarm),
                                title: Text(
                                  'Ruta: ${data['rutaNombre'] ?? ''}',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['mensaje'] ?? ''),
                                    if (hora != null) ...[
                                      Text(
                                        'Fecha: ${hora.day}/${hora.month}/${hora.year}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'Hora: ${TimeOfDay.fromDateTime(hora).format(context)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await docs[index].reference.delete();
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
