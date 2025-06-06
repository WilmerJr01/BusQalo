import 'package:busqalo/utils/registroDeActividad.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileDrawer extends StatelessWidget {
  final String? nombre;
  final String? apellido;
  final String? ciudad;
  final String? correo;
  final String? fechaNacimiento;
  final String? photoUrl;
  final VoidCallback onLogout;

  const ProfileDrawer({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.ciudad,
    required this.correo,
    required this.fechaNacimiento,
    required this.photoUrl,
    required this.onLogout,
  });

  Future<void> enviarPQRS(BuildContext context) async {
    final TextEditingController tipoController = TextEditingController();
    final TextEditingController mensajeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Enviar PQRS',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          
        ), 
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'Petición', child: Text('Petición')),
                  DropdownMenuItem(value: 'Queja', child: Text('Queja')),
                  DropdownMenuItem(value: 'Reclamo', child: Text('Reclamo')),
                  DropdownMenuItem(
                    value: 'Sugerencia',
                    child: Text('Sugerencia'),
                  ),
                ],
                onChanged: (value) => tipoController.text = value ?? '',
              ),
              TextField(
                controller: mensajeController,
                decoration: InputDecoration(labelText: 'Mensaje', alignLabelWithHint: true),
                maxLength: 500,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
            label: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final tipo = tipoController.text.trim();
              final mensaje = mensajeController.text.trim();

              if (tipo.isEmpty || mensaje.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, completa todos los campos.'),
                  ),
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;

              final pqrsRef = FirebaseFirestore.instance.collection('pqrs');
              await pqrsRef.add({
                'tipo': tipo,
                'mensaje': mensaje,
                'usuarioId': user?.uid,
                'correo': user?.email,
                'fecha': Timestamp.now(),
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PQRS enviada exitosamente.')),
              );

              Navigator.pop(context);
              RegistroDeActividad.registrarActividad(
                'Envío de PQRS: $tipo',
              );
            },
            label: const Text('Enviar'),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Perfil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent, width: 3),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                      ? NetworkImage(photoUrl!)
                      : null,
                  child: (photoUrl == null || photoUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      nombre != null || apellido != null
                          ? '${nombre ?? ''} ${apellido ?? ''}'
                          : 'Cargando...',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    correo != null ? 'Correo: $correo' : 'Cargando...',
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    fechaNacimiento != null
                        ? 'Fecha de Nacimiento: $fechaNacimiento'
                        : '',
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => enviarPQRS(context),
                      icon: const Icon(
                        Icons.edit_document,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: const Text('PQRS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 40,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout, size: 20, color: Colors.white),
                      label: const Text('Cerrar sesión', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
