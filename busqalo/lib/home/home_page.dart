import 'package:busqalo/home/body.dart';
import 'package:busqalo/login/login_page.dart';
import 'package:busqalo/home/profile.dart';
import 'package:busqalo/utils/registroDeActividad.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? nombre;
  String? ciudad;
  String? correo;
  String? photoUrl;
  String? apellido;
  String? fechaNacimiento;


  @override
  void initState() {
    super.initState();
    _loadUserData();
    RegistroDeActividad.registrarActividad('Accedió a la página de inicio');
  }

  String formatFecha(String fechaStr) {
    try {
      final date = DateTime.parse(fechaStr); // parsea el string ISO 8601
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return fechaStr; // si falla, devuelve la fecha sin cambiar
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          nombre = userDoc['nombre'] ?? '';
          apellido = userDoc['apellido'] ?? '';
          ciudad = userDoc['ciudad'] ?? '';
          fechaNacimiento = userDoc['fechaNacimiento'] ?? '';
          photoUrl = userDoc['photoURL'] ?? '';
          correo = user.email;
        });
      }
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final tween = Tween(begin: 0.0, end: 1.0);
                  return FadeTransition(
                    opacity: animation.drive(tween),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 600),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.green,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      drawer: ProfileDrawer(
        nombre: nombre,
        apellido: apellido,
        ciudad: ciudad,
        correo: correo,
        fechaNacimiento: fechaNacimiento != null
            ? formatFecha(fechaNacimiento!)
            : '',
        photoUrl: photoUrl,
        onLogout: _handleLogout,
      ),

      body: Stack(
        children: [
          // Body que va full pantalla
          HomeBody(
            nombre: nombre,
            ciudad: ciudad,
            correo: correo,
            photoUrl: photoUrl,
            apellido: apellido,
            fechaNacimiento: fechaNacimiento,
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70 + MediaQuery.of(context).padding.top,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Hola, $nombre',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 10,
                      child: Builder(
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: photoUrl != null && photoUrl!.isNotEmpty
                              ? Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: NetworkImage(photoUrl!),
                                    radius: 18,
                                  ),
                                )
                              : const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
