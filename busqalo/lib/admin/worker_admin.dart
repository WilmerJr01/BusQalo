import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminConductoresPage extends StatefulWidget {
  const AdminConductoresPage({super.key});

  @override
  State<AdminConductoresPage> createState() => _AdminConductoresPageState();
}

class _AdminConductoresPageState extends State<AdminConductoresPage> {
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final cedulaController = TextEditingController();
  final salarioController = TextEditingController();
  final celularController = TextEditingController();
  DateTime? fechaNacimiento;
  String? conductorIdEditando;
  String filtroCedula = '';

  void _mostrarFormulario({Map<String, dynamic>? data, String? docId}) {
    if (data != null) {
      nombreController.text = data['nombre'] ?? '';
      apellidoController.text = data['apellido'] ?? '';
      cedulaController.text = data['cedula'] ?? '';
      salarioController.text = data['salario'].toString();
      celularController.text = data['celular'] ?? '';
      fechaNacimiento = (data['fechaNacimiento'] as Timestamp?)?.toDate();
      conductorIdEditando = docId;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(docId == null ? 'Añadir Conductor' : 'Editar Conductor'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: apellidoController,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                ),
                TextField(
                  controller: cedulaController,
                  decoration: const InputDecoration(labelText: 'Cédula'),
                ),
                TextField(
                  controller: salarioController,
                  decoration: const InputDecoration(labelText: 'Salario'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: celularController,
                  decoration: const InputDecoration(labelText: 'Celular'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: fechaNacimiento ?? DateTime(1990),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (selected != null) {
                      setStateDialog(() {
                        fechaNacimiento = selected;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    fechaNacimiento == null
                        ? 'Seleccionar Fecha de Nacimiento'
                        : 'Nacimiento: ${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _cancelarFormulario,
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _guardarConductor,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelarFormulario() {
    Navigator.pop(context);
    _limpiarFormulario();
  }

  void _limpiarFormulario() {
    nombreController.clear();
    apellidoController.clear();
    cedulaController.clear();
    salarioController.clear();
    celularController.clear();
    fechaNacimiento = null;
    conductorIdEditando = null;
  }

  Future<void> _guardarConductor({
    Map<String, dynamic>? data,
    String? docId,
  }) async {
    final nombre = nombreController.text.trim();
    final apellido = apellidoController.text.trim();
    final cedula = cedulaController.text.trim();
    final salario = salarioController.text.trim();
    final celular = celularController.text.trim();

    if ([nombre, apellido, cedula, salario, celular].any((e) => e.isEmpty) ||
        fechaNacimiento == null)
      return;

    final nuevoConductor = {
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'salario': salario,
      'celular': celular,
      'fechaNacimiento': Timestamp.fromDate(fechaNacimiento!),
      'createdAt': FieldValue.serverTimestamp(),
    };

    // 🔍 Buscar si ya existe una cédula (cuando estás creando uno nuevo)
    if (docId == null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('conductores')
          .where('cedula', isEqualTo: cedula)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // 🛑 Ya existe un conductor con esa cédula
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya existe un conductor con esa cédula'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('conductores')
          .add(nuevoConductor);
      _limpiarFormulario();
    } else {
      // ✅ Editando conductor existente
      await FirebaseFirestore.instance
          .collection('conductores')
          .doc(docId)
          .update(nuevoConductor);
    }

    Navigator.pop(context);
  }

  Future<void> _eliminarConductor(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este conductor?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text('Eliminar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('conductores')
          .doc(docId)
          .delete();
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    cedulaController.dispose();
    salarioController.dispose();
    celularController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conductores')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Añadir Conductor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => _mostrarFormulario(),
            ),
            const SizedBox(height: 20),

            // 🔍 Caja de búsqueda por cédula
            TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por cédula',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  filtroCedula = value.trim();
                });
              },
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('conductores')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;

                  // 🧠 Aplicar filtro por cédula
                  final filtrados = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final cedula = data['cedula']?.toString() ?? '';
                    return cedula.contains(filtroCedula);
                  }).toList();

                  if (filtrados.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Oops... no hay coincidencias',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final doc = filtrados[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final nombreCompleto =
                          '${data['nombre']} ${data['apellido']}';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(nombreCompleto),
                          subtitle: Text(
                            'Cédula: ${data['cedula']}\nCelular: ${data['celular']}\nSalario: \$${data['salario']}',
                          ),
                          trailing: Wrap(
                            spacing: 10,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () => _mostrarFormulario(
                                  data: data,
                                  docId: doc.id,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _eliminarConductor(doc.id),
                              ),
                            ],
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
