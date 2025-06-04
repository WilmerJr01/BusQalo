import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminBusesPage extends StatefulWidget {
  const AdminBusesPage({super.key});

  @override
  State<AdminBusesPage> createState() => _AdminBusesPageState();
}

class _AdminBusesPageState extends State<AdminBusesPage> {
  final conductorController = TextEditingController();
  final proveedorController = TextEditingController();
  final placaController = TextEditingController();
  final tipoController = TextEditingController();

  final nombreProveedorController = TextEditingController();
  final comisionController = TextEditingController();
  final nitController = TextEditingController();
  DateTime? fechaInicio;
  DateTime? fechaFin;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _mostrarFormularioBus({DocumentSnapshot? busExistente}) async {
    List<String> conductores = [];
    List<String> proveedores = [];

    final conductoresSnap = await FirebaseFirestore.instance
        .collection('conductores')
        .get();
    final proveedoresSnap = await FirebaseFirestore.instance
        .collection('proveedores')
        .get();

    conductores = conductoresSnap.docs
        .map((doc) => doc['nombre'].toString())
        .toList();

    final now = DateTime.now();
    proveedores = proveedoresSnap.docs
        .where((doc) {
          final inicio = doc['fechaInicio'];
          final fin = doc['fechaFin'];
          if (inicio is Timestamp && fin is Timestamp) {
            final fechaInicio = inicio.toDate();
            final fechaFin = fin.toDate();
            return now.isAfter(fechaInicio) && now.isBefore(fechaFin);
          }
          return false; // Solo proveedores con fechas válidas
        })
        .map((doc) => doc['nombre'].toString())
        .toList();

    String? selectedConductor = busExistente != null
        ? (busExistente.data() as Map<String, dynamic>)['conductor']
        : null;
    String? selectedProveedor = busExistente != null
        ? (busExistente.data() as Map<String, dynamic>)['proveedor']
        : null;

    placaController.text = busExistente != null
        ? (busExistente.data() as Map<String, dynamic>)['placa'] ?? ''
        : '';
    tipoController.text = busExistente != null
        ? (busExistente.data() as Map<String, dynamic>)['tipo'] ?? ''
        : '';

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: Text(busExistente != null ? 'Editar Bus' : 'Nuevo Bus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedConductor,
              items: conductores.map((nombre) {
                return DropdownMenuItem(value: nombre, child: Text(nombre));
              }).toList(),
              onChanged: (valor) => setState(() => selectedConductor = valor),
              decoration: const InputDecoration(labelText: 'Conductor'),
            ),
            DropdownButtonFormField<String>(
              value: selectedProveedor,
              items: proveedores.map((nombre) {
                return DropdownMenuItem(value: nombre, child: Text(nombre));
              }).toList(),
              onChanged: (valor) => setState(() => selectedProveedor = valor),
              decoration: const InputDecoration(labelText: 'Proveedor'),
            ),
            TextField(
              controller: placaController,
              decoration: const InputDecoration(labelText: 'Placa'),
            ),
            TextField(
              controller: tipoController,
              decoration: const InputDecoration(labelText: 'Tipo de bus'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (selectedConductor == null || selectedProveedor == null)
                return;

              final nuevoBus = {
                'conductor': selectedConductor,
                'proveedor': selectedProveedor,
                'placa': placaController.text,
                'tipo': tipoController.text,
                'createdAt': FieldValue.serverTimestamp(),
              };

              if (busExistente != null) {
                FirebaseFirestore.instance
                    .collection('buses')
                    .doc(busExistente.id)
                    .update(nuevoBus);
              } else {
                FirebaseFirestore.instance.collection('buses').add(nuevoBus);
              }

              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _eliminarBus(String busId) {
    FirebaseFirestore.instance.collection('buses').doc(busId).delete();
  }

  void _mostrarFormularioProveedor({DocumentSnapshot? proveedorExistente}) {
    if (proveedorExistente != null) {
      final data = proveedorExistente.data() as Map<String, dynamic>;
      nombreProveedorController.text = data['nombre'];
      comisionController.text = data['comision'];
      nitController.text = data['nit'];
      fechaInicio = (data['fechaInicio'] as Timestamp).toDate();
      fechaFin = (data['fechaFin'] as Timestamp).toDate();
    } else {
      nombreProveedorController.clear();
      comisionController.clear();
      nitController.clear();
      fechaInicio = null;
      fechaFin = null;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nuevo Proveedor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreProveedorController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del proveedor',
                  ),
                ),
                TextField(
                  controller: comisionController,
                  decoration: const InputDecoration(labelText: 'Comisión'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: nitController,
                  decoration: const InputDecoration(labelText: 'NIT'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      label: Text(
                        fechaInicio == null
                            ? 'Seleccionar Fecha de Inicio'
                            : 'Inicio del Convenio: ${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}',
                      ),
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fechaInicio ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: fechaFin ?? DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() => fechaInicio = picked);
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      label: Text(
                        fechaFin == null
                            ? 'Seleccionar Fecha de Finalización'
                            : 'Fin del Convenio: ${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}',
                      ),
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              fechaInicio ?? fechaFin ?? DateTime.now(),
                          firstDate: fechaInicio ?? DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() => fechaFin = picked);
                        }
                      },
                    ),
                  ],
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
                final nombre = nombreProveedorController.text.trim();
                final comision = comisionController.text.trim();
                final nit = nitController.text.trim();

                if (nombre.isEmpty ||
                    comision.isEmpty ||
                    nit.isEmpty ||
                    fechaInicio == null ||
                    fechaFin == null)
                  return;

                final data = {
                  'nombre': nombre,
                  'nit': nit,
                  'comision': comision,
                  'fechaInicio': Timestamp.fromDate(fechaInicio!),
                  'fechaFin': Timestamp.fromDate(fechaFin!),
                  'createdAt': FieldValue.serverTimestamp(),
                };

                if (proveedorExistente != null) {
                  await FirebaseFirestore.instance
                      .collection('proveedores')
                      .doc(proveedorExistente.id)
                      .update(data);
                } else {
                  final nitExistente = await FirebaseFirestore.instance
                      .collection('proveedores')
                      .where('nit', isEqualTo: nit)
                      .get();
                  if (nitExistente.docs.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El NIT ya está registrado.'),
                      ),
                    );
                    return;
                  }
                  await FirebaseFirestore.instance
                      .collection('proveedores')
                      .add(data);
                }

                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _eliminarProveedor(String proveedorId) {
    FirebaseFirestore.instance
        .collection('proveedores')
        .doc(proveedorId)
        .delete();
  }

  Widget _buildBusesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('buses')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final buses = snapshot.data!.docs;
        if (buses.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.search_off, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Oops... no buses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          );
        }

        return ListView.builder(
          itemCount: buses.length,
          itemBuilder: (context, index) {
            final busDoc = buses[index];
            final bus = busDoc.data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_bus),
                  title: Text('Placa: ${bus['placa']}'),
                  subtitle: Text(
                    'Tipo: ${bus['tipo']} \n'
                    'Conductor: ${bus['conductor'] ?? 'No asignado'}\n'
                    'Proveedor: ${bus['proveedor'] ?? 'No asignado'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _mostrarFormularioBus(busExistente: busDoc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarBus(busDoc.id),
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

  Widget _buildProveedoresList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('proveedores')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final proveedores = snapshot.data!.docs;
        if (proveedores.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.search_off, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Oops... no hay proveedores',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          );
        }

        return ListView.builder(
          itemCount: proveedores.length,
          itemBuilder: (context, index) {
            final proveedorDoc = proveedores[index];
            final proveedor = proveedorDoc.data() as Map<String, dynamic>;

            if (proveedor['fechaFin'] != null &&
                proveedor['fechaFin'] is Timestamp) {
              final fechaFin = (proveedor['fechaFin'] as Timestamp).toDate();
              if (fechaFin.isBefore(DateTime.now())) {
                return const SizedBox.shrink(); // No mostrar proveedores vencidos
              }
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.business),
                  title: Text(proveedor['nombre']),
                  subtitle: Text(
                    'NIT: ${proveedor['nit']} - Comisión: \$${proveedor['comision']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _mostrarFormularioProveedor(
                          proveedorExistente: proveedorDoc,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarProveedor(proveedorDoc.id),
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
      appBar: AppBar(title: const Text('Buses y Proveedores')),
      body: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_bus, size: 20),
                onPressed: () => _mostrarFormularioBus(),
                label: const Text('Agregar Bus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.business, size: 20),
                onPressed: () => _mostrarFormularioProveedor(),
                label: const Text('Agregar Proveedor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_bus,
                color: _currentPage == 0 ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.business,
                color: _currentPage == 1 ? Colors.green : Colors.grey,
              ),
            ],
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [_buildBusesList(), _buildProveedoresList()],
            ),
          ),
        ],
      ),
    );
  }
}
