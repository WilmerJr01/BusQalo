import 'package:busqalo/admin/live_emition.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'car_admin.dart';
import 'worker_admin.dart';
import 'routes_admin.dart';

class RutaAdminPage extends StatelessWidget {
  const RutaAdminPage({super.key});

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('No se encontró usuario logueado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.engineering),
              label: const Text('Administrar Conductores'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 20,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminConductoresPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            ElevatedButton.icon(
              icon: const Icon(Icons.directions_bus),
              label: const Text('Administrar Buses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 40,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminBusesPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            ElevatedButton.icon(
              icon: const Icon(Icons.route),
              label: const Text('Administrar Rutas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 197, 183, 58),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 40,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminRoutesPage(),
                  ),
                );
              },
            ),
            SizedBox(height: 5),
            ElevatedButton.icon(
              icon: const Icon(Icons.signal_wifi_4_bar_rounded),
              label: const Text('Emitir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LiveLocationPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
