import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveLocationPage extends StatefulWidget {
  const LiveLocationPage({super.key});

  @override
  State<LiveLocationPage> createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  String? rutaSeleccionada;
  Timer? _timer;
  bool enviando = false;
  User? _user;

  List<String> rutasDisponibles = [];
  bool cargandoRutas = true;

  @override
  void initState() {
    super.initState();
    _cargarRutasDesdeFirestore();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarRutasDesdeFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('rutas').get();
    final rutas = snapshot.docs.map((doc) => doc['nombre'] as String).toList();

    setState(() {
      rutasDisponibles = rutas;
      cargandoRutas = false;
    });
  }

  Future<void> enviarUbicacion() async {
    if (_user == null || rutaSeleccionada == null) return;

    final position = await Geolocator.getCurrentPosition();

    final emitionRef = FirebaseFirestore.instance
        .collection('emisiones')
        .doc(_user!.uid);

    final now = DateTime.now();

    await emitionRef.set({
      'emitiendo': enviando,
      'ubicaciones': FieldValue.arrayUnion([
        {
          'latitud': position.latitude,
          'longitud': position.longitude,
          'ruta': rutaSeleccionada,
          'timestamp': now,
        },
      ]),
    }, SetOptions(merge: true));
  }

  void iniciarEnvio() {
    if (rutaSeleccionada == null) return;

    setState(() => enviando = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      enviarUbicacion();
    });
  }

  Future<void> detenerEnvio() async {
    _timer?.cancel();
    setState(() => enviando = false);
    if (_user != null) {
      await FirebaseFirestore.instance
          .collection('emisiones')
          .doc(_user!.uid)
          .set({'emitiendo': false}, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Envío de Ubicación')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: cargandoRutas
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Selecciona una ruta',
                    ),
                    value: rutaSeleccionada,
                    items: rutasDisponibles
                        .map(
                          (ruta) =>
                              DropdownMenuItem(value: ruta, child: Text(ruta)),
                        )
                        .toList(),
                    onChanged: (valor) =>
                        setState(() => rutaSeleccionada = valor),
                  ),
                  const SizedBox(height: 24),
                  // ...existing code...
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RawMaterialButton(
                            onPressed: enviando ? detenerEnvio : iniciarEnvio,
                            elevation: 6.0,
                            fillColor: enviando ? Colors.red : Colors.green,
                            shape: const CircleBorder(),
                            constraints: const BoxConstraints.tightFor(
                              width: 90,
                              height: 90,
                            ),
                            child: Icon(
                              enviando ? Icons.stop : Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            enviando ? 'Detener' : 'Iniciar',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ...existing code...
                ],
              ),
      ),
    );
  }
}
